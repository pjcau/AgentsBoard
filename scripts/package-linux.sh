#!/usr/bin/env bash
set -euo pipefail

# Build Linux packages (.deb + .AppImage) for AgentsBoard
# Requires: swift toolchain, dpkg-deb, appimagetool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

VERSION=$(grep 'version' tauri/Cargo.toml | head -1 | sed 's/.*"\(.*\)"/\1/')
ARCH=$(uname -m)
BUILD_DIR="$PROJECT_DIR/build/linux"

echo "=== Building AgentsBoard $VERSION for Linux ($ARCH) ==="

# Build server binary
echo "--- Building AgentsBoardServer ---"
swift build --target AgentsBoardServer -c release
SERVER_BIN="$PROJECT_DIR/.build/release/AgentsBoardServer"

if [ ! -f "$SERVER_BIN" ]; then
    echo "Error: Server binary not found at $SERVER_BIN"
    exit 1
fi

# Build .deb package
echo "--- Building .deb package ---"
DEB_DIR="$BUILD_DIR/deb"
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/local/bin"
mkdir -p "$DEB_DIR/usr/share/applications"

cp "$SERVER_BIN" "$DEB_DIR/usr/local/bin/agentsboard-server"
chmod 755 "$DEB_DIR/usr/local/bin/agentsboard-server"

cat > "$DEB_DIR/DEBIAN/control" <<EOF
Package: agentsboard
Version: $VERSION
Section: devel
Priority: optional
Architecture: $(dpkg --print-architecture 2>/dev/null || echo amd64)
Depends: libsqlite3-0
Maintainer: AgentsBoard <support@agentsboard.dev>
Description: AI Agent Mission Control
 Fleet management, code review, and orchestration for AI coding agents.
EOF

dpkg-deb --build "$DEB_DIR" "$BUILD_DIR/agentsboard_${VERSION}_${ARCH}.deb" 2>/dev/null || \
    echo "dpkg-deb not available, skipping .deb"

echo "=== Done ==="
ls -la "$BUILD_DIR/" 2>/dev/null || true
