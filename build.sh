#!/bin/bash
set -euo pipefail

# AgentsBoard — Build & Package into .app bundle
APP_NAME="AgentsBoard"
BUNDLE_ID="com.agentsboard.app"
VERSION="$(cat VERSION 2>/dev/null || echo '0.0.0')"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# Kill running instance if open
if pgrep -x "$APP_NAME" > /dev/null 2>&1; then
    echo "▸ Closing running $APP_NAME..."
    pkill -x "$APP_NAME"
    sleep 0.5
fi

echo "▸ Building $APP_NAME..."
swift build -c debug 2>&1 | tail -3

echo "▸ Packaging into $APP_BUNDLE..."

# Create bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp ".build/debug/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy icon if exists
if [ -f "Sources/App/Resources/AppIcon.icns" ]; then
    cp "Sources/App/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Write Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
</dict>
</plist>
PLIST

# Ad-hoc code sign (required for macOS to trust the binary)
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null

echo "▸ Done! Launching $APP_NAME..."
open "$APP_BUNDLE"
