#!/usr/bin/env bash
set -euo pipefail

# Build Linux packages for AgentsBoard
# - Server .deb (headless, server-only)
# - Desktop .deb (Qt app + CoreFFI)
# Requires: docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

VERSION=$(cat VERSION 2>/dev/null || echo '0.0.0')
ARCH="${1:-amd64}"
BUILD_DIR="$PROJECT_DIR/build/linux"

echo "=== Building AgentsBoard $VERSION for Linux ($ARCH) ==="

mkdir -p "$BUILD_DIR"

# Build server .deb via Docker
echo "--- Building server .deb ---"
docker build -t agentsboard-server --platform "linux/$ARCH" -f Dockerfile .
docker create --name ab-extract agentsboard-server 2>/dev/null || docker rm ab-extract && docker create --name ab-extract agentsboard-server
docker cp ab-extract:/usr/local/bin/agentsboard-server "$BUILD_DIR/agentsboard-server-linux-$ARCH"
docker rm ab-extract
echo "Server binary: $BUILD_DIR/agentsboard-server-linux-$ARCH"

# Build Qt desktop .deb via Docker
echo "--- Building Qt desktop .deb ---"
docker build -f Dockerfile.qt \
    --target=package \
    --build-arg VERSION="$VERSION" \
    --build-arg ARCH="$ARCH" \
    --platform "linux/$ARCH" \
    --output="$BUILD_DIR" .

echo ""
echo "=== Done ==="
ls -la "$BUILD_DIR/" 2>/dev/null || true
