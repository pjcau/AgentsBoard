#!/bin/bash
# MARK: - DMG Builder (Step 20.1)
# Creates a DMG installer with custom layout.

set -euo pipefail

DEFAULT_VERSION="$(cat VERSION 2>/dev/null || echo '0.0.0')"
VERSION="${1:-$DEFAULT_VERSION}"
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

# Create DMG with app, Applications symlink, and README
mkdir -p build/dmg_contents
cp -R "$APP_PATH" build/dmg_contents/
ln -sf /Applications build/dmg_contents/Applications

# Add first-launch instructions for unsigned app
cat > build/dmg_contents/READ\ ME\ FIRST.txt << 'README'
╔══════════════════════════════════════════════════════════════╗
║                   AgentsBoard — First Launch                ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  macOS may block this app because it is not signed with a    ║
║  Developer ID certificate.                                   ║
║                                                              ║
║  To open AgentsBoard:                                        ║
║                                                              ║
║  Option A — Right-click to open (recommended):               ║
║    1. Drag AgentsBoard.app to /Applications                  ║
║    2. Right-click (or Control-click) AgentsBoard.app         ║
║    3. Select "Open" from the context menu                    ║
║    4. Click "Open" in the dialog that appears                ║
║    (You only need to do this once)                           ║
║                                                              ║
║  Option B — System Settings:                                 ║
║    1. Try to open AgentsBoard.app normally                   ║
║    2. Go to System Settings > Privacy & Security             ║
║    3. Scroll down to find the message about AgentsBoard      ║
║    4. Click "Open Anyway"                                    ║
║                                                              ║
║  Option C — Terminal:                                        ║
║    Run: xattr -cr /Applications/AgentsBoard.app              ║
║    Then open the app normally.                               ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
README

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
