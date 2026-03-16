#!/bin/bash
# MARK: - Release Script (Step 20.1)
# Tag, changelog, GitHub Release, upload assets.

set -euo pipefail

VERSION="${1:?Usage: release.sh <version>}"
TAG="v${VERSION}"

echo "=== Releasing AgentsBoard ${TAG} ==="

# 1. Verify clean state
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Working directory not clean"
    exit 1
fi

# 2. Build
echo "Building..."
./scripts/bundle.sh "$VERSION"
./scripts/build-dmg.sh "$VERSION"

# 3. Generate changelog
echo "Generating changelog..."
PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$PREV_TAG" ]; then
    CHANGELOG=$(git log "${PREV_TAG}..HEAD" --pretty=format:"- %s" --no-merges)
else
    CHANGELOG=$(git log --pretty=format:"- %s" --no-merges)
fi

# 4. Tag
echo "Tagging ${TAG}..."
git tag -a "$TAG" -m "Release ${VERSION}"

# 5. Push tag
echo "Pushing tag..."
git push origin "$TAG"

# 6. Create GitHub Release
echo "Creating GitHub Release..."
gh release create "$TAG" \
    --title "AgentsBoard ${VERSION}" \
    --notes "## What's New

${CHANGELOG}

## Installation

### Homebrew
\`\`\`bash
brew install --cask agentsboard
\`\`\`

### Manual
Download \`AgentsBoard-${VERSION}.dmg\` below.

> **Note:** macOS may block the app on first launch. Right-click the app and select \"Open\", or go to **System Settings → Privacy & Security** and click **Open Anyway**.
" \
    "build/AgentsBoard-${VERSION}.dmg"

echo ""
echo "=== Release Complete ==="
echo "Tag: ${TAG}"
echo "GitHub: $(gh release view "$TAG" --json url -q .url)"
