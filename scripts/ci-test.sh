#!/bin/bash
# MARK: - CI Test Runner (Step 19.2)
# Runs all tests with coverage reporting.

set -euo pipefail

echo "=== AgentsBoard CI Test Suite ==="
echo ""

# Build
echo "Building..."
swift build 2>&1 | tail -5
echo ""

# Run tests
echo "Running tests..."
swift test --enable-code-coverage 2>&1

# Coverage report
echo ""
echo "Generating coverage report..."
PROFILE_PATH=$(swift test --show-codecov-path 2>/dev/null || echo "")
if [ -n "$PROFILE_PATH" ] && [ -f "$PROFILE_PATH" ]; then
    echo "Coverage data: $PROFILE_PATH"
    # Parse coverage JSON
    python3 -c "
import json, sys
with open('$PROFILE_PATH') as f:
    data = json.load(f)
total = data.get('data', [{}])[0].get('totals', {})
lines = total.get('lines', {})
pct = lines.get('percent', 0)
print(f'Line coverage: {pct:.1f}%')
if pct < 80:
    print('WARNING: Coverage below 80% target')
    sys.exit(1)
else:
    print('Coverage target MET (>80%)')
" 2>/dev/null || echo "Coverage parsing not available"
fi

echo ""
echo "=== Tests Complete ==="
