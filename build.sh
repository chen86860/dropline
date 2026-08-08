#!/bin/bash
# 构建 Dropline.app（Apple Silicon 原生）
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$(pwd)"
APP="$ROOT/dist/Dropline.app"
BUNDLE_ID="dev.emmmm.Dropline"
# 版本号默认取 CHANGELOG.md 里最新的一条，避免和发布内容脱节
VERSION="${DROPLINE_VERSION:-$("$ROOT/Tools/changelog.py" --latest)}"

# Sparkle 自动更新：appcast.xml 作为 Release 资产随每次发布上传，
# /releases/latest/download/ 永远指向最新一个正式 Release，无需回写仓库
FEED_URL="https://github.com/chen86860/dropline/releases/latest/download/appcast.xml"
# 与钥匙串里的 EdDSA 私钥配对；用 Tools/sparkle.sh pubkey 可重新打印
SU_PUBLIC_KEY="F7NNg2b/Lpgv6EprFu5YcR6DApLrwc5yfPOmI7o5hOk="

echo "==> 编译 (release, arm64)"
swift build -c release --arch arm64
BIN="$(swift build -c release --arch arm64 --show-bin-path)/Dropline"

echo "==> 组装 .app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Dropline"

echo "==> 打包 Finder 扩展 (.appex)"
EXT="$APP/Contents/PlugIns/DroplineFinder.appex"
EXT_ID="${BUNDLE_ID}.Finder"
SDK_VERSION=$(xcrun --sdk macosx --show-sdk-version)
SDK_NAME="macosx${SDK_VERSION}"
OS_BUILD=$(sw_vers -buildVersion)
mkdir -p "$EXT/Contents/MacOS"
cp "$(dirname "$BIN")/DroplineFinder" "$EXT/Contents/MacOS/DroplineFinder"
cat > "$EXT/Contents/Info.plist" <<EXTPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>              <string>DroplineFinder</string>
    <key>CFBundleDisplayName</key>       <string>Dropline</string>
    <key>CFBundleExecutable</key>        <string>DroplineFinder</string>
    <key>CFBundleIdentifier</key>        <string>${EXT_ID}</string>
    <key>CFBundlePackageType</key>       <string>XPC!</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key>           <string>${VERSION}</string>
    <key>CFBundleSupportedPlatforms</key><array><string>MacOSX</string></array>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleDevelopmentRegion</key> <string>en</string>
    <!-- pkd 用这些平台键判定扩展是否可用，缺了会被静默忽略 -->
    <key>DTPlatformName</key>            <string>macosx</string>
    <key>DTSDKName</key>                 <string>${SDK_NAME}</string>
    <key>DTPlatformVersion</key>         <string>${SDK_VERSION}</string>
    <key>DTCompiler</key>                <string>com.apple.compilers.llvm.clang.1_0</string>
    <key>BuildMachineOSBuild</key>       <string>${OS_BUILD}</string>
    <key>LSMinimumSystemVersion</key>    <string>13.0</string>
    <key>NSPrincipalClass</key>          <string>NSApplication</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key><dict/>
        <key>NSExtensionPointIdentifier</key><string>com.apple.FinderSync</string>
        <key>NSExtensionPrincipalClass</key><string>DroplineFinderSync</string>
    </dict>
</dict>
</plist>
EXTPLIST

echo "==> 嵌入 Sparkle.framework"
SPARKLE_FW=$(find "$ROOT/.build/artifacts" -type d -name "Sparkle.framework" -path "*macos*" | head -1)
if [ -z "$SPARKLE_FW" ]; then
  echo "❌ 找不到 Sparkle.framework，先执行：swift package resolve"; exit 1
fi
mkdir -p "$APP/Contents/Frameworks"
cp -R "$SPARKLE_FW" "$APP/Contents/Frameworks/"

echo "==> 生成图标"
ICONSET="$ROOT/dist/Dropline.iconset"
rm -rf "$ICONSET"; mkdir -p "$ICONSET"
swift "$ROOT/Tools/makeicon.swift" "$ROOT/dist/icon-1024.png"
for s in 16 32 64 128 256 512 1024; do
  sips -z $s $s "$ROOT/dist/icon-1024.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
done
mv "$ICONSET/icon_1024x1024.png" "$ICONSET/icon_512x512@2x.png"
cp "$ICONSET/icon_512x512.png" "$ICONSET/icon_256x256@2x.png"
cp "$ICONSET/icon_256x256.png" "$ICONSET/icon_128x128@2x.png"
cp "$ICONSET/icon_64x64.png"   "$ICONSET/icon_32x32@2x.png"
cp "$ICONSET/icon_32x32.png"   "$ICONSET/icon_16x16@2x.png"
rm -f "$ICONSET/icon_64x64.png"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Dropline.icns"
rm -rf "$ICONSET" "$ROOT/dist/icon-1024.png"

echo "==> 写入 Info.plist"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>              <string>Dropline</string>
    <key>CFBundleDisplayName</key>       <string>Dropline</string>
    <key>CFBundleExecutable</key>        <string>Dropline</string>
    <key>CFBundleIdentifier</key>        <string>${BUNDLE_ID}</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key>           <string>${VERSION}</string>
    <key>CFBundleIconFile</key>          <string>Dropline</string>
    <key>LSMinimumSystemVersion</key>    <string>13.0</string>
    <!-- 界面语言由 App 自己按 Locale 解析（设置里可覆盖），这里只声明支持的语言，
         让系统知道服务菜单等系统级文案有中英两份 -->
    <key>CFBundleDevelopmentRegion</key> <string>en</string>
    <key>CFBundleLocalizations</key>
    <array><string>en</string><string>zh-Hans</string></array>
    <key>NSHighResolutionCapable</key>   <true/>
    <key>NSHumanReadableCopyright</key>  <string>MIT License · github.com/chen86860/dropline</string>

    <!-- Sparkle 自动更新 -->
    <key>SUFeedURL</key>                 <string>${FEED_URL}</string>
    <key>SUPublicEDKey</key>             <string>${SU_PUBLIC_KEY}</string>
    <key>SUEnableAutomaticChecks</key>   <true/>
    <key>SUScheduledCheckInterval</key>  <integer>86400</integer>

    <!-- Finder 扩展通过 dropline://upload?list=… 把选中文件交给主 App -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>    <string>${BUNDLE_ID}</string>
            <key>CFBundleURLSchemes</key> <array><string>dropline</string></array>
        </dict>
    </array>

    <!-- 允许把任意文件拖到 Dock 图标上传 -->
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>     <string>Any File</string>
            <key>CFBundleTypeRole</key>     <string>Viewer</string>
            <key>LSHandlerRank</key>        <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array><string>public.item</string></array>
        </dict>
    </array>

    <!-- Finder 右键 →「服务」→「使用 Dropline 上传」
         注意：文件类服务必须用 NSSendTypes = NSFilenamesPboardType 搭配
         NSRequiredContext/NSTextContent = FilePath；换成 NSSendFileTypes 菜单不会出现。
         NSMenuItem 是「语言 → 标题」的字典，default 兜底英文；这项由系统语言决定，
         跟随不了 App 内的语言设置。 -->
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>  <string>Upload with Dropline</string>
                <key>zh_CN</key>    <string>使用 Dropline 上传</string>
                <key>zh-Hans</key>  <string>使用 Dropline 上传</string>
                <key>Chinese</key>  <string>使用 Dropline 上传</string>
            </dict>
            <key>NSMessage</key>    <string>uploadFromService</string>
            <key>NSPortName</key>   <string>Dropline</string>
            <key>NSRequiredContext</key>
            <dict><key>NSTextContent</key><string>FilePath</string></dict>
            <key>NSSendTypes</key>
            <array><string>NSFilenamesPboardType</string></array>
        </dict>
    </array>
</dict>
</plist>
PLIST

echo "==> 签名 (ad-hoc)"
# Sparkle 内含 XPC Service 与 Autoupdate/Updater.app，必须由内向外逐层签名
SIGN_ID="${DROPLINE_SIGN_ID:--}"
# hardened runtime 会启用库验证：ad-hoc 签名下主程序与框架的 Team ID 不一致，
# 会导致 dyld 拒绝加载 Sparkle。只有用真实 Developer ID 时才开启（公证需要）。
if [ "$SIGN_ID" = "-" ]; then
  SIGN_OPTS=()
  echo "    使用 ad-hoc 签名（本地使用）；发布请设 DROPLINE_SIGN_ID=\"Developer ID Application: ...\""
else
  SIGN_OPTS=(--options runtime --timestamp)
fi

FW="$APP/Contents/Frameworks/Sparkle.framework"
for nested in \
  "$FW/Versions/B/XPCServices/"*.xpc \
  "$FW/Versions/B/Autoupdate" \
  "$FW/Versions/B/Updater.app"; do
  [ -e "$nested" ] && codesign --force "${SIGN_OPTS[@]+"${SIGN_OPTS[@]}"}" --sign "$SIGN_ID" "$nested"
done
codesign --force "${SIGN_OPTS[@]+"${SIGN_OPTS[@]}"}" --sign "$SIGN_ID" "$FW"
codesign --force "${SIGN_OPTS[@]+"${SIGN_OPTS[@]}"}" \
  --entitlements "$ROOT/Resources/DroplineFinder.entitlements" --sign "$SIGN_ID" "$EXT"
codesign --force "${SIGN_OPTS[@]+"${SIGN_OPTS[@]}"}" --sign "$SIGN_ID" "$APP"

LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

# 列出 LaunchServices 里注册的所有 Dropline.app。dump 出来每行形如
#   path:                       /Applications/Dropline.app (0xabb0)
# 末尾那个十六进制 ID 必须去掉，否则按路径结尾匹配永远匹配不上。
dropline_registrations() {
  "$LSREGISTER" -dump 2>/dev/null \
    | sed -n 's/^[[:space:]]*path:[[:space:]]*//p' \
    | sed 's/ (0x[0-9a-f]*)$//' \
    | grep -E '/Dropline\.app$' \
    | sort -u
}

# 打包发布时不要注册 dist/ 里的副本，否则会和 /Applications 里的形成两份注册
if [ "${DROPLINE_SKIP_REGISTER:-0}" = "1" ]; then
  echo ""
  echo "✅ 完成（未注册）：$APP"
  exit 0
fi

# 右键「服务」菜单只应有一份注册；同一 Bundle ID 存在多份副本会导致菜单项消失或点击无响应。
if [ "${1:-}" = "--install" ]; then
  echo "==> 退出正在运行的 Dropline"
  # 先礼后兵：正在跑才发退出事件（不判断的话 osascript 会把没在跑的 App 先拉起来再退）
  if pgrep -x Dropline >/dev/null 2>&1; then
    osascript -e 'tell application id "dev.emmmm.Dropline" to quit' >/dev/null 2>&1 || true
    for _ in $(seq 20); do pgrep -x Dropline >/dev/null 2>&1 || break; sleep 0.2; done
    pkill -x Dropline 2>/dev/null || true
  fi
  # 扩展是独立进程，旧版留着会继续用旧代码弹菜单
  pkill -f 'DroplineFinder' 2>/dev/null || true

  echo "==> 卸载旧版本"
  # 图床配置存在 UserDefaults（~/Library/Preferences/dev.emmmm.Dropline.plist）和登录钥匙串里，
  # 都按 Bundle ID 索引，不随 .app 删除 —— 所以下面只删程序本体，配置和密钥原样保留。
  rm -rf /Applications/Dropline.app

  # 同一 Bundle ID 在 LaunchServices 里有多份注册，右键服务菜单就会失效。
  # 最常见的来源是装过的 DMG：卷推出后注册仍留在库里，路径早已不存在
  # （这种「死」注册照样能用 lsregister -u 按原路径销掉）。
  echo "==> 清理旧注册"
  while IFS= read -r stale; do
    [ -n "$stale" ] || continue
    if [ -e "$stale" ]; then
      # 可能是用户自己放在别处的副本或挂载中的 DMG，只注销、不替他删文件
      echo "    注销另一份副本（文件保留，不再需要请自行删除）：$stale"
    else
      echo "    清除已失效的残留注册：$stale"
    fi
    "$LSREGISTER" -u "$stale" 2>/dev/null || true
  done < <(dropline_registrations)
  "$LSREGISTER" -u "$APP" 2>/dev/null || true
  "$LSREGISTER" -gc 2>/dev/null || true   # 压缩数据库，清掉 GC 得掉的陈旧条目

  echo "==> 安装到 /Applications"
  # 用 mv 而不是 cp：dist/ 里若残留一份副本，LaunchServices 会自动把它重新索引，
  # 变成同一 Bundle ID 的两份注册，右键服务菜单就会消失。
  mv "$APP" /Applications/Dropline.app
  TARGET=/Applications/Dropline.app
else
  TARGET="$APP"
  if [ -d /Applications/Dropline.app ]; then
    echo "⚠️  /Applications/Dropline.app 已存在，两份副本会让右键服务菜单失效。"
    echo "    请改用：./build.sh --install"
  fi
fi

echo "==> 注册服务菜单"
"$LSREGISTER" -f "$TARGET" || true
killall -u "$USER" pbs 2>/dev/null || true   # 让 pbs 重新读取注册表
sleep 1
/System/Library/CoreServices/pbs -flush >/dev/null 2>&1 || true

DUPES=$(dropline_registrations | grep -c . || true)
if [ "${DUPES:-0}" -gt 1 ]; then
  echo "⚠️  LaunchServices 中存在多份 Dropline.app 注册，右键服务可能失效："
  dropline_registrations | sed 's/^/      /'
  echo "    逐个注销（路径已不存在也照样能销）："
  echo "      $LSREGISTER -u \"<上面的路径>\" && $LSREGISTER -gc"
fi

if [ "${1:-}" = "--install" ]; then
  # 换掉 .app 之后访达扩展的启用状态可能丢失，重新打开一次
  echo "==> 启用访达扩展"
  pluginkit -a "$TARGET/Contents/PlugIns/DroplineFinder.appex" 2>/dev/null || true
  pluginkit -e use -i dev.emmmm.Dropline.Finder 2>/dev/null || true

  echo "==> 启动 Dropline"
  open "$TARGET"
fi

echo ""
echo "✅ 完成：$TARGET"
