#!/bin/bash
# Sparkle 发布助手
#
#   ./Tools/sparkle.sh pubkey            打印 EdDSA 公钥（应与 build.sh 里的 SU_PUBLIC_KEY 一致）
#   ./Tools/sparkle.sh export-key        导出私钥，用于配置 GitHub Actions 的 secret
#   ./Tools/sparkle.sh release 1.0.1     构建 → 打包 → 签名 → 生成 appcast → 发 GitHub Release
#
# 正常发版请改用推 tag：git tag v1.0.1 && git push origin v1.0.1
# （见 .github/workflows/release.yml）。本脚本的 release 只作应急/离线用途 ——
# 它建 tag 时会一并触发那个工作流，等于发两次。
#
# 私钥保存在登录钥匙串（由 Sparkle 的 generate_keys 创建），不在仓库里。
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
REPO="chen86860/dropline"
RELEASES="$ROOT/dist/releases"

TOOLS=$(find "$ROOT/.build/artifacts" -type d -name bin -path "*sparkle*" | head -1)
if [ -z "$TOOLS" ]; then
  echo "❌ 找不到 Sparkle 工具，先执行：swift package resolve"; exit 1
fi

case "${1:-}" in
pubkey)
  "$TOOLS/generate_keys" -p
  ;;

export-key)
  # 把钥匙串里的 EdDSA 私钥导出成文件，用于配置 GitHub Actions 的
  # SPARKLE_PRIVATE_KEY secret。文件已在 .gitignore 里，用完请删掉。
  OUT="$ROOT/sparkle-private-key.txt"
  "$TOOLS/generate_keys" -x "$OUT"
  echo ""
  echo "私钥已导出到：$OUT"
  echo "接下来："
  echo "  1. gh secret set SPARKLE_PRIVATE_KEY --repo $REPO < \"$OUT\""
  echo "     （或到 GitHub → Settings → Secrets and variables → Actions 手动粘贴）"
  echo "  2. rm \"$OUT\""
  ;;

release)
  VERSION="${2:-}"
  [ -n "$VERSION" ] || { echo "用法: $0 release <版本号，如 1.0.1>"; exit 1; }

  echo "⚠️  正常发版请推 tag（git tag v$VERSION && git push origin v$VERSION）由 CI 完成。"
  echo "    本地发布会在远端建出同名 tag，从而再触发一次 Release 工作流。"
  printf "    仍要在本机发布？[y/N] "
  read -r answer
  case "$answer" in [yY]*) ;; *) echo "已取消"; exit 1 ;; esac

  # 发布说明的唯一来源是 CHANGELOG.md；没写条目就直接中止，避免发出没有说明的版本
  echo "==> 读取 CHANGELOG.md"
  NOTES_MD=$("$ROOT/Tools/changelog.py" "$VERSION") || exit 1
  mkdir -p "$RELEASES"
  printf '%s\n' "$NOTES_MD" > "$RELEASES/notes-$VERSION.md"

  echo "==> 构建 $VERSION"
  DROPLINE_VERSION="$VERSION" DROPLINE_SKIP_REGISTER=1 "$ROOT/build.sh" >/dev/null

  echo "==> 打包"
  mkdir -p "$RELEASES"
  ZIP="$RELEASES/Dropline-$VERSION.zip"
  rm -f "$ZIP"
  ditto -c -k --sequesterRsrc --keepParent "$ROOT/dist/Dropline.app" "$ZIP"
  # 打完包就删掉 dist 里的副本：留着会被 LaunchServices 索引，
  # 和 /Applications 里的形成两份注册，右键菜单会失效
  LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
  "$LSREGISTER" -u "$ROOT/dist/Dropline.app" 2>/dev/null || true
  rm -rf "$ROOT/dist/Dropline.app"

  # 更新说明输出成 HTML 片段（无 DOCTYPE/body），generate_appcast 会把它内嵌进
  # appcast 的 <description>，于是不需要单独托管更新说明文件。
  # appcast 每次从零重建，历史版本的说明也要一并备好，否则老条目会没有说明。
  echo "==> 生成更新说明"
  for zip in "$RELEASES"/Dropline-*.zip; do
    [ -e "$zip" ] || continue
    v=$(basename "$zip" .zip); v=${v#Dropline-}
    "$ROOT/Tools/changelog.py" "$v" --fragment > "$RELEASES/Dropline-$v.html" 2>/dev/null \
      || { echo "   ⚠️  CHANGELOG.md 里没有 $v，该版本不带更新说明"
           rm -f "$RELEASES/Dropline-$v.html"; }
    # 中文那份带 .zh-Hans 后缀，generate_appcast 不会认它，稍后由 appcast_i18n.py 注入
    "$ROOT/Tools/changelog.py" "$v" --lang zh --fragment > "$RELEASES/Dropline-$v.zh-Hans.html" 2>/dev/null \
      || { echo "   ⚠️  CHANGELOG.zh-CN.md 里没有 $v，该版本没有中文更新说明"
           rm -f "$RELEASES/Dropline-$v.zh-Hans.html"; }
  done

  echo "==> 生成并签名 appcast"
  APPCAST="$ROOT/dist/appcast.xml"
  "$TOOLS/generate_appcast" "$RELEASES" \
    --embed-release-notes \
    --download-url-prefix "https://github.com/$REPO/releases/download/v$VERSION/" \
    -o "$APPCAST"

  # generate_appcast 对目录里所有历史包用同一个前缀；按各自版本改回对应的 tag
  python3 - "$APPCAST" "$REPO" <<'PY'
import re, sys
path, repo = sys.argv[1], sys.argv[2]
xml = open(path).read()
def fix(m):
    ver = m.group(1)
    return f'url="https://github.com/{repo}/releases/download/v{ver}/Dropline-{ver}.zip"'
xml = re.sub(r'url="[^"]*/Dropline-([0-9][^"/]*)\.zip"', fix, xml)
open(path, "w").write(xml)
print("appcast 下载地址已按版本对齐 tag")
PY

  # 每个条目再补一份 xml:lang="zh-Hans" 的说明
  "$ROOT/Tools/appcast_i18n.py" "$APPCAST" "$RELEASES"

  # generate_appcast 还会为历史版本生成增量包，appcast 里引用的是本次 tag 下的地址，
  # 必须一并上传，否则老版本用户下载增量包会 404
  # appcast.xml 也作为资产上传：客户端的更新源固定指向
  # /releases/latest/download/appcast.xml，永远解析到最新一个正式 Release
  ASSETS=("$ZIP" "$APPCAST")
  while IFS= read -r delta; do ASSETS+=("$delta"); done < <(ls "$RELEASES"/*"$VERSION"-*.delta 2>/dev/null || true)
  echo "==> 发布 GitHub Release（${#ASSETS[@]} 个资产）"
  # Release 正文用 CHANGELOG 的 Markdown 原文，再附上 Gatekeeper 提示
  NOTES_FILE="$RELEASES/notes-$VERSION.md"
  {
    echo
    echo "---"
    echo
    echo 'ad-hoc 签名，首次打开请右键 App →「打开」，或执行：'
    echo '`xattr -dr com.apple.quarantine /Applications/Dropline.app`'
  } >> "$NOTES_FILE"

  gh release create "v$VERSION" "${ASSETS[@]}" \
    --repo "$REPO" \
    --title "Dropline $VERSION" \
    --notes-file "$NOTES_FILE" \
    || { gh release upload "v$VERSION" "${ASSETS[@]}" --repo "$REPO" --clobber
         gh release edit "v$VERSION" --repo "$REPO" --notes-file "$NOTES_FILE"; }

  echo ""
  echo "✅ 已发布 v$VERSION"
  echo "   feed: https://github.com/$REPO/releases/latest/download/appcast.xml"
  ;;

*)
  echo "用法: $0 {pubkey|export-key|release <版本号>}"; exit 1
  ;;
esac
