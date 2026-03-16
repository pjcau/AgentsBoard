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

# Create installer script that removes quarantine and installs
cat > build/dmg_contents/Install\ AgentsBoard.command << 'INSTALLER'
#!/bin/bash
# AgentsBoard Installer
# This script installs the app and removes the macOS quarantine flag
# so you don't get the "damaged app" error.

clear
echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║     AgentsBoard — Installer              ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

APP_SRC="$(dirname "$0")/AgentsBoard.app"
APP_DST="/Applications/AgentsBoard.app"

if [ ! -d "$APP_SRC" ]; then
    echo "  ✗ Error: AgentsBoard.app not found in DMG."
    echo "    Press any key to exit..."
    read -n1
    exit 1
fi

# Copy to Applications
echo "  → Installing to /Applications..."
if [ -d "$APP_DST" ]; then
    rm -rf "$APP_DST"
fi
cp -R "$APP_SRC" "$APP_DST"

# Remove quarantine flag
echo "  → Removing quarantine flag..."
xattr -cr "$APP_DST"

echo ""
echo "  ✔ AgentsBoard installed successfully!"
echo ""
echo "  → Launching AgentsBoard..."
echo ""

open "$APP_DST"

# Close Terminal window after 2 seconds
sleep 2
osascript -e 'tell application "Terminal" to close front window' 2>/dev/null &
INSTALLER
chmod +x build/dmg_contents/Install\ AgentsBoard.command

# Add README with instructions
cat > build/dmg_contents/READ\ ME\ FIRST.txt << 'README'
╔══════════════════════════════════════════════════════════════╗
║                   AgentsBoard — First Launch                ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  RECOMMENDED: Double-click "Install AgentsBoard.command"     ║
║  It will install the app and open it automatically.          ║
║                                                              ║
║  If you prefer to install manually:                          ║
║                                                              ║
║  1. Drag AgentsBoard.app to /Applications                    ║
║  2. Open Terminal and run:                                   ║
║     xattr -cr /Applications/AgentsBoard.app                  ║
║  3. Open AgentsBoard from /Applications                      ║
║                                                              ║
║  DO NOT double-click AgentsBoard.app directly from the DMG   ║
║  — macOS will block it as "damaged".                         ║
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
