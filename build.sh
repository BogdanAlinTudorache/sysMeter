#!/bin/bash
set -e

APP_NAME="sysMeter"
BUILD_DIR="$(pwd)/build"
CONTENTS_DIR="$BUILD_DIR/$APP_NAME.app/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building $APP_NAME..."

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "Adding Application Icon..."
cp "/System/Applications/Utilities/Activity Monitor.app/Contents/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

echo "Compiling Swift source..."
swiftc main.swift \
    -parse-as-library \
    -o "$MACOS_DIR/$APP_NAME" \
    -suppress-warnings

chmod +x "$MACOS_DIR/$APP_NAME"

cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>sysMeter</string>
    <key>CFBundleIdentifier</key>
    <string>com.bogdantudorache.sysMeter</string>
    <key>CFBundleName</key>
    <string>sysMeter</string>
    <key>CFBundleDisplayName</key>
    <string>sysMeter</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo ""
echo "Build complete!"
echo "   $BUILD_DIR/$APP_NAME.app"
echo ""

if pgrep -x "$APP_NAME" > /dev/null; then
    echo "Quitting running $APP_NAME..."
    pkill -x "$APP_NAME"
    sleep 0.5
fi

echo "Installing to /Applications..."
rm -rf "/Applications/$APP_NAME.app"
cp -r "$BUILD_DIR/$APP_NAME.app" "/Applications/"
echo "Installed: /Applications/$APP_NAME.app"
echo ""

echo "Launching $APP_NAME..."
open "/Applications/$APP_NAME.app"