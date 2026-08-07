#!/bin/bash
# Sparkle 发布助手
#
#   ./Tools/sparkle.sh pubkey            打印 EdDSA 公钥（应与 build.sh 里的 SU_PUBLIC_KEY 一致）
#   ./Tools/sparkle.sh release 1.0.1     构建 → 打包 → 签名 → 生成 appcast → 发 GitHub Release → 推送
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

release)
  VERSION="${2:-}"
  [ -n "$VERSION" ] || { echo "用法: $0 release <版本号，如 1.0.1>"; exit 1; }

  echo "==> 构建 $VERSION"
  DROPLINE_VERSION="$VERSION" DROPLINE_SKIP_REGISTER=1 "$ROOT/build.sh" >/dev/null

  echo "==> 打包"
  mkdir -p "$RELEASES"
  ZIP="$RELEASES/Dropline-$VERSION.zip"
  rm -f "$ZIP"
  ditto -c -k --sequesterRsrc --keepParent "$ROOT/dist/Dropline.app" "$ZIP"

  echo "==> 生成并签名 appcast"
  "$TOOLS/generate_appcast" "$RELEASES" \
    --download-url-prefix "https://github.com/$REPO/releases/download/v$VERSION/" \
    -o "$ROOT/appcast.xml"

  # generate_appcast 对目录里所有历史包用同一个前缀；按各自版本改回对应的 tag
  python3 - "$ROOT/appcast.xml" "$REPO" <<'PY'
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

  # generate_appcast 还会为历史版本生成增量包，appcast 里引用的是本次 tag 下的地址，
  # 必须一并上传，否则老版本用户下载增量包会 404
  ASSETS=("$ZIP")
  while IFS= read -r delta; do ASSETS+=("$delta"); done < <(ls "$RELEASES"/*"$VERSION"-*.delta 2>/dev/null || true)
  echo "==> 发布 GitHub Release（${#ASSETS[@]} 个资产）"
  gh release create "v$VERSION" "${ASSETS[@]}" \
    --repo "$REPO" \
    --title "Dropline $VERSION" \
    --notes "Dropline $VERSION

安装后首次打开若被 Gatekeeper 拦截，右键 App →「打开」。" \
    || gh release upload "v$VERSION" "${ASSETS[@]}" --repo "$REPO" --clobber

  # appcast 里的 releaseNotesLink 是相对 appcast.xml 推导出来的仓库根路径，
  # 所以更新说明 HTML 必须放进仓库根目录（不是 Release 资产）
  if [ -f "$RELEASES/Dropline-$VERSION.html" ]; then
    cp "$RELEASES/Dropline-$VERSION.html" "$ROOT/Dropline-$VERSION.html"
    git add "Dropline-$VERSION.html"
  fi

  echo "==> 提交 appcast"
  git add appcast.xml
  git commit -m "Release $VERSION: update appcast" || true
  git push

  echo ""
  echo "✅ 已发布 v$VERSION"
  echo "   feed: https://raw.githubusercontent.com/$REPO/main/appcast.xml"
  ;;

*)
  echo "用法: $0 {pubkey|release <版本号>}"; exit 1
  ;;
esac
