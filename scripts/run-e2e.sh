#!/bin/bash
# MARK: - E2E Test Runner
# Builds the app, generates an Xcode project for UI testing, and runs XCUITests.
#
# Usage: bash scripts/run-e2e.sh
#
# Requirements:
# - Xcode installed and `xcodebuild` available
# - macOS 14+ (Sonoma)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_PATH="$PROJECT_DIR/build/AgentsBoard.app"
XCODEPROJ="$PROJECT_DIR/AgentsBoardE2E.xcodeproj"

echo "=== AgentsBoard E2E Tests ==="

# Step 1: Build the app
echo "▸ Building app..."
cd "$PROJECT_DIR"
bash build.sh 2>&1 | tail -3

if [ ! -d "$APP_PATH" ]; then
    echo "✘ App not found at $APP_PATH"
    exit 1
fi
echo "✔ App built: $APP_PATH"

# Step 2: Generate minimal Xcode project for XCUITest (if not exists)
if [ ! -d "$XCODEPROJ" ]; then
    echo "▸ Generating Xcode project for E2E tests..."
    bash scripts/generate-e2e-project.sh
fi

# Step 3: Run XCUITests
echo "▸ Running E2E tests..."
xcodebuild test \
    -project "$XCODEPROJ" \
    -scheme "AgentsBoardE2ETests" \
    -destination "platform=macOS" \
    -resultBundlePath "$PROJECT_DIR/build/e2e-results" \
    APP_PATH="$APP_PATH" \
    2>&1 | xcpretty 2>/dev/null || xcodebuild test \
    -project "$XCODEPROJ" \
    -scheme "AgentsBoardE2ETests" \
    -destination "platform=macOS" \
    -resultBundlePath "$PROJECT_DIR/build/e2e-results" \
    APP_PATH="$APP_PATH" \
    2>&1 | tail -30

echo ""
echo "=== E2E Tests Complete ==="
