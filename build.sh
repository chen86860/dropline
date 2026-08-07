#!/bin/bash
# 构建 Dropline.app（Apple Silicon 原生）
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$(pwd)"
APP="$ROOT/dist/Dropline.app"
BUNDLE_ID="dev.emmmm.Dropline"
VERSION="${DROPLINE_VERSION:-1.0.0}"

# Sparkle 自动更新
FEED_URL="https://raw.githubusercontent.com/chen86860/dropline/main/appcast.xml"
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
    <key>NSHighResolutionCapable</key>   <true/>
    <key>NSHumanReadableCopyright</key>  <string>github.com/chen86860/dropline</string>

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
         NSRequiredContext/NSTextContent = FilePath；换成 NSSendFileTypes 菜单不会出现。 -->
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict><key>default</key><string>使用 Dropline 上传</string></dict>
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

# 打包发布时不要注册 dist/ 里的副本，否则会和 /Applications 里的形成两份注册
if [ "${DROPLINE_SKIP_REGISTER:-0}" = "1" ]; then
  echo ""
  echo "✅ 完成（未注册）：$APP"
  exit 0
fi

# 右键「服务」菜单只应有一份注册；同一 Bundle ID 存在多份副本会导致菜单项消失或点击无响应。
if [ "${1:-}" = "--install" ]; then
  echo "==> 安装到 /Applications"
  osascript -e 'tell application "Dropline" to quit' 2>/dev/null || true
  pkill -x Dropline 2>/dev/null || true
  sleep 1
  "$LSREGISTER" -u /Applications/Dropline.app 2>/dev/null || true
  "$LSREGISTER" -u "$APP" 2>/dev/null || true
  rm -rf /Applications/Dropline.app
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

DUPES=$("$LSREGISTER" -dump 2>/dev/null | grep -c "path: .*/Dropline.app" || true)
if [ "${DUPES:-0}" -gt 1 ]; then
  echo "⚠️  LaunchServices 中存在多份 Dropline.app 注册，右键服务可能失效。"
  "$LSREGISTER" -dump 2>/dev/null | grep "path: .*/Dropline.app" | sort -u
fi

echo ""
echo "✅ 完成：$TARGET"
echo "   打开：open \"$TARGET\""
[ "${1:-}" = "--install" ] || echo "   安装到应用程序文件夹（推荐，右键服务更稳定）：./build.sh --install"
