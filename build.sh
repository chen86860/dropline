#!/bin/bash
# 构建 Dropline.app（Apple Silicon 原生）
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$(pwd)"
APP="$ROOT/dist/Dropline.app"
BUNDLE_ID="dev.emmmm.Dropline"
VERSION="1.0.0"

echo "==> 编译 (release, arm64)"
swift build -c release --arch arm64
BIN="$(swift build -c release --arch arm64 --show-bin-path)/Dropline"

echo "==> 组装 .app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Dropline"

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
    <key>NSHumanReadableCopyright</key>  <string>Dropline</string>

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
codesign --force --deep --sign - "$APP"

LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

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
