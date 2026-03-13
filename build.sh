#!/bin/bash
set -euo pipefail

# AgentsBoard — Build & Package into .app bundle
APP_NAME="AgentsBoard"
BUNDLE_ID="com.agentsboard.app"
VERSION="0.1.0"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "▸ Building $APP_NAME..."
swift build -c debug 2>&1 | tail -3

echo "▸ Packaging into $APP_BUNDLE..."

# Create bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp ".build/arm64-apple-macosx/debug/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

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

echo "▸ Done! Run with:"
echo "  open $APP_BUNDLE"
