#!/bin/bash
# 用 create-dmg 打一个带背景图的安装器：dist/Dropline.dmg
#
#   ./tools/dmg.sh              # 版本号取 CHANGELOG 最新条目
#   ./tools/dmg.sh 1.2.0        # 指定版本号
#
# 文件名不带版本号，这样 Release 资产名每次都一样，
# /releases/latest/download/Dropline.dmg 就永远指向最新一个正式版
#（和 appcast.xml 用的是同一个套路）。版本号仍写在卷名和 App 的 Info.plist 里。
#
# 环境变量：
#   DMG_SKIP_STYLE=1      跳过访达美化，直接出裸 DMG（调试用，快很多）
#   DMG_REQUIRE_STYLE=1   美化没生效就直接失败，不允许静默降级（发布流程用）
#
# 依赖：brew install create-dmg
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
VERSION="${1:-$("$ROOT/tools/changelog.py" --latest)}"
APP="$ROOT/dist/Dropline.app"
DMG="$ROOT/dist/Dropline.dmg"

command -v create-dmg >/dev/null || { echo "❌ 缺少 create-dmg，请先执行：brew install create-dmg"; exit 1; }

# 没有现成的构建产物就先构建（不注册，避免和 /Applications 里的形成两份注册）
if [ ! -d "$APP" ]; then
  echo "==> 构建 $VERSION"
  DROPLINE_VERSION="$VERSION" DROPLINE_SKIP_REGISTER=1 "$ROOT/build.sh" >/dev/null
fi

echo "==> 生成背景图"
BG_DIR="$ROOT/dist/dmg-bg"
rm -rf "$BG_DIR"; mkdir -p "$BG_DIR"
swift "$ROOT/tools/makedmgbg.swift" "$BG_DIR/bg.png" 1
swift "$ROOT/tools/makedmgbg.swift" "$BG_DIR/bg@2x.png" 2
# 合成带 HiDPI 的 tiff，Retina 屏上才不会糊
tiffutil -cathidpicheck "$BG_DIR/bg.png" "$BG_DIR/bg@2x.png" -out "$BG_DIR/bg.tiff"

echo "==> 打包 DMG"
rm -f "$DMG"

make_dmg() {
  create-dmg \
    --volname "Dropline $VERSION" \
    --volicon "$APP/Contents/Resources/Dropline.icns" \
    --background "$BG_DIR/bg.tiff" \
    --window-pos 200 120 \
    --window-size 540 380 \
    --icon-size 128 \
    --icon "Dropline.app" 150 180 \
    --hide-extension "Dropline.app" \
    --app-drop-link 390 180 \
    --no-internet-enable \
    "$@" \
    "$DMG" "$APP"
}

# CI 日志里也要显眼
warn() {
  echo "⚠️  $1"
  [ "${GITHUB_ACTIONS:-}" = "true" ] && echo "::warning::$1" || true
}

# 背景图、图标位置、窗口大小全靠 create-dmg 调访达的 AppleScript 写进卷里。
# 关掉这一步的开关在 create-dmg 那边叫 --skip-jenkins —— 纯属上游的历史命名，
# 当年是给 Jenkins 那种没有图形会话的 CI 用的，和本仓库无关，这里只按它的原名传参。
# 这段偶尔会撞上 "Can't get disk (-1728)"，重试一般就过；真的做不到才降级。
STYLED=0
if [ "${DMG_SKIP_STYLE:-0}" = "1" ]; then
  make_dmg --skip-jenkins
else
  for attempt in 1 2 3; do
    rm -f "$DMG"
    if make_dmg; then STYLED=1; break; fi
    warn "访达美化第 $attempt 次失败，5 秒后重试"
    sleep 5
  done
  if [ "$STYLED" = "0" ]; then
    warn "访达美化最终失败，只能出裸 DMG：没有背景图与图标位置"
    rm -f "$DMG"
    make_dmg --skip-jenkins
  fi
fi

rm -rf "$BG_DIR"

# 光看 create-dmg 的退出码不够：真正决定「好不好看」的是访达写进卷里的 .DS_Store
# （背景图文件在跳过美化时也照样会被拷进去，不能拿它当判据）。挂载实测一次。
echo "==> 校验 DMG 布局"
MOUNT="$(mktemp -d)"
hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$MOUNT" >/dev/null
[ -f "$MOUNT/.DS_Store" ] && LAYOUT_OK=1 || LAYOUT_OK=0
hdiutil detach "$MOUNT" >/dev/null || true
# 挂载期间 LaunchServices 可能把临时路径下的 App 也登记了，和 /Applications 里的重复
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
[ -x "$LSREG" ] && "$LSREG" -u "$MOUNT/Dropline.app" 2>/dev/null || true
rmdir "$MOUNT" 2>/dev/null || true

if [ "$LAYOUT_OK" = "1" ]; then
  echo "    ✓ 窗口布局已写入（.DS_Store 存在）"
else
  warn "DMG 里没有 .DS_Store，打开后会是默认的裸窗口（无背景图、图标位置错乱）"
  # 发布流程里把它当硬错误，免得又悄悄发出一个丑 DMG
  if [ "${DMG_REQUIRE_STYLE:-0}" = "1" ]; then
    echo "❌ DMG_REQUIRE_STYLE=1，构建中止"
    exit 1
  fi
fi

# create-dmg 过程中会临时挂载 /Volumes/dmg.XXXX，卷卸载后 LaunchServices 里仍会留下
# 指向它的注册记录，和 /Applications 里的形成重复注册，右键菜单会失效。这里清掉。
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
if [ -x "$LSREGISTER" ]; then
  # 没有残留时 grep 返回 1，在 set -o pipefail 下会直接终止脚本，所以要兜住
  STALE=$("$LSREGISTER" -dump 2>/dev/null | grep -o '/Volumes/dmg\.[^/]*/Dropline\.app' | sort -u || true)
  if [ -n "$STALE" ]; then
    while IFS= read -r entry; do
      [ -n "$entry" ] && "$LSREGISTER" -u "$entry" 2>/dev/null || true
    done <<< "$STALE"
  fi
fi

# 注意：变量后面紧跟全角括号时必须用 ${} 包起来，否则 bash 会把多字节字符
# 当成变量名的一部分，在 set -u 下直接报 unbound variable
SIZE=$(du -h "$DMG" | cut -f1 | tr -d ' ')
echo ""
# 文件名不再带版本号，日志里把版本补出来，免得分不清这份是哪个版本
echo "✅ 完成：${DMG}（${VERSION}，${SIZE}）"
