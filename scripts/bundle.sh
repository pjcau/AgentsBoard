#!/bin/bash
# MARK: - Build & Bundle Script (Step 20.1)
# Build, sign, notarize, and package AgentsBoard.

set -euo pipefail

DEFAULT_VERSION="$(cat VERSION 2>/dev/null || echo '0.0.0')"
VERSION="${1:-$DEFAULT_VERSION}"
BUNDLE_ID="com.agentsboard.app"
TEAM_ID="${TEAM_ID:-}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application}"

echo "=== Building AgentsBoard v${VERSION} ==="

# 1. Clean build
echo "Cleaning..."
swift package clean 2>/dev/null || true
rm -rf .build/release

# 2. Release build
echo "Building release..."
swift build -c release

# 3. Create .app bundle
APP_DIR="build/AgentsBoard.app"
CONTENTS="${APP_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Copy binary
cp .build/release/AgentsBoard "$MACOS/"

# Copy app icon
if [ -f "Sources/App/Resources/AppIcon.icns" ]; then
    cp "Sources/App/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

# Create Info.plist
cat > "${CONTENTS}/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>AgentsBoard</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>AgentsBoard</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
</dict>
</plist>
PLIST

echo "App bundle created at ${APP_DIR}"

# 4. Code signing
if [ -n "$TEAM_ID" ]; then
    # Full Developer ID signing
    echo "Signing with Developer ID..."
    codesign --force --deep --sign "$SIGNING_IDENTITY" \
        --options runtime \
        --entitlements Entitlements.plist \
        "$APP_DIR"
    echo "Signed with Developer ID"
else
    # Ad-hoc signing — changes Gatekeeper error from "damaged" to "unidentified developer"
    # Users can then approve via System Settings → Open Anyway
    echo "Ad-hoc signing..."
    codesign --force --deep --sign - "$APP_DIR"
    echo "Ad-hoc signed (users approve via System Settings → Open Anyway)"
fi

# 5. Notarization (if credentials available)
if [ -n "${NOTARIZE_PROFILE:-}" ]; then
    echo "Submitting for notarization..."
    ditto -c -k --keepParent "$APP_DIR" "build/AgentsBoard.zip"
    xcrun notarytool submit "build/AgentsBoard.zip" \
        --keychain-profile "$NOTARIZE_PROFILE" \
        --wait
    xcrun stapler staple "$APP_DIR"
    echo "Notarization complete"
fi

echo ""
echo "=== Build Complete ==="
echo "Output: ${APP_DIR}"
echo "Version: ${VERSION}"
