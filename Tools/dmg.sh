#!/bin/bash
# 用 create-dmg 打一个带背景图的安装器：dist/Dropline-<版本>.dmg
#
#   ./Tools/dmg.sh              # 版本号取 CHANGELOG 最新条目
#   ./Tools/dmg.sh 1.2.0        # 指定版本号
#
# 依赖：brew install create-dmg
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
VERSION="${1:-$("$ROOT/Tools/changelog.py" --latest)}"
APP="$ROOT/dist/Dropline.app"
DMG="$ROOT/dist/Dropline-$VERSION.dmg"

command -v create-dmg >/dev/null || { echo "❌ 缺少 create-dmg，请先执行：brew install create-dmg"; exit 1; }

# 没有现成的构建产物就先构建（不注册，避免和 /Applications 里的形成两份注册）
if [ ! -d "$APP" ]; then
  echo "==> 构建 $VERSION"
  DROPLINE_VERSION="$VERSION" DROPLINE_SKIP_REGISTER=1 "$ROOT/build.sh" >/dev/null
fi

echo "==> 生成背景图"
BG_DIR="$ROOT/dist/dmg-bg"
rm -rf "$BG_DIR"; mkdir -p "$BG_DIR"
swift "$ROOT/Tools/makedmgbg.swift" "$BG_DIR/bg.png" 1
swift "$ROOT/Tools/makedmgbg.swift" "$BG_DIR/bg@2x.png" 2
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

# create-dmg 会用 AppleScript 让访达把窗口摆好看，这一步在无 GUI 环境（CI）里会失败；
# 失败后用 --skip-jenkins 重来一次，只是窗口布局不生效，DMG 本身照常可用。
if [ "${DMG_SKIP_JENKINS:-0}" = "1" ]; then
  make_dmg --skip-jenkins
elif ! make_dmg; then
  echo "⚠️  访达美化步骤失败（多半是无 GUI 环境），改用 --skip-jenkins 重试"
  rm -f "$DMG"
  make_dmg --skip-jenkins
fi

rm -rf "$BG_DIR"

# 注意：变量后面紧跟全角括号时必须用 ${} 包起来，否则 bash 会把多字节字符
# 当成变量名的一部分，在 set -u 下直接报 unbound variable
SIZE=$(du -h "$DMG" | cut -f1 | tr -d ' ')
echo ""
echo "✅ 完成：${DMG}（${SIZE}）"
