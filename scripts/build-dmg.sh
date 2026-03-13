#!/bin/bash
# MARK: - DMG Builder (Step 20.1)
# Creates a DMG installer with custom layout.

set -euo pipefail

VERSION="${1:-0.1.0}"
APP_PATH="build/AgentsBoard.app"
DMG_NAME="AgentsBoard-${VERSION}.dmg"
DMG_PATH="build/${DMG_NAME}"
VOLUME_NAME="AgentsBoard"

echo "=== Creating DMG ==="

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not found at $APP_PATH"
    echo "Run bundle.sh first"
    exit 1
fi

# Create temporary DMG
TEMP_DMG="build/temp_${DMG_NAME}"
rm -f "$DMG_PATH" "$TEMP_DMG"

# Create DMG with app and Applications symlink
mkdir -p build/dmg_contents
cp -R "$APP_PATH" build/dmg_contents/
ln -sf /Applications build/dmg_contents/Applications

hdiutil create "$TEMP_DMG" \
    -volname "$VOLUME_NAME" \
    -srcfolder build/dmg_contents \
    -ov -format UDRW

# Convert to compressed DMG
hdiutil convert "$TEMP_DMG" \
    -format UDZO \
    -o "$DMG_PATH"

# Cleanup
rm -f "$TEMP_DMG"
rm -rf build/dmg_contents

echo ""
echo "=== DMG Created ==="
echo "Output: ${DMG_PATH}"
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
