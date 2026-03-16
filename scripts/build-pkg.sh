#!/bin/bash
# Build a .pkg installer for AgentsBoard.
# The pkg installs the app to /Applications and removes quarantine flags.

set -euo pipefail

VERSION="${1:-$(cat VERSION 2>/dev/null || echo '0.0.0')}"
APP_PATH="build/AgentsBoard.app"
PKG_PATH="build/AgentsBoard-${VERSION}.pkg"
STAGING="build/pkg-staging"
SCRIPTS="build/pkg-scripts"

echo "=== Building PKG Installer v${VERSION} ==="

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo "✘ App not found at $APP_PATH — run bundle.sh first"
    exit 1
fi

# Clean staging
rm -rf "$STAGING" "$SCRIPTS"
mkdir -p "$STAGING/Applications" "$SCRIPTS"

# Copy app to staging
cp -R "$APP_PATH" "$STAGING/Applications/AgentsBoard.app"

# Create postinstall script — removes quarantine after install
cat > "$SCRIPTS/postinstall" << 'POSTINSTALL'
#!/bin/bash
# Remove quarantine flag so Gatekeeper doesn't block the unsigned app
xattr -cr "/Applications/AgentsBoard.app" 2>/dev/null || true
echo "AgentsBoard installed successfully."
exit 0
POSTINSTALL
chmod +x "$SCRIPTS/postinstall"

# Build the .pkg
pkgbuild \
    --root "$STAGING" \
    --scripts "$SCRIPTS" \
    --identifier "com.agentsboard.app" \
    --version "$VERSION" \
    --install-location "/" \
    "$PKG_PATH"

# Clean up staging
rm -rf "$STAGING" "$SCRIPTS"

echo ""
echo "=== PKG Created ==="
echo "Output: $PKG_PATH"
ls -lh "$PKG_PATH" | awk '{print "Size: " $5}'
