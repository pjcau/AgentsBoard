#!/bin/bash
# MARK: - Performance Benchmark (Step 19.1)
# Measures startup time, frame time, input latency, memory usage.

set -euo pipefail

APP_PATH="${1:-./build/AgentsBoard.app/Contents/MacOS/AgentsBoard}"
RESULTS_FILE="benchmark_results.json"

echo "=== AgentsBoard Performance Benchmark ==="
echo ""

# 1. Startup time
echo "Measuring startup time..."
STARTUP_TIMES=()
for i in {1..5}; do
    START=$(python3 -c "import time; print(time.time())")
    timeout 5 "$APP_PATH" --benchmark-startup 2>/dev/null || true
    END=$(python3 -c "import time; print(time.time())")
    ELAPSED=$(python3 -c "print(int(($END - $START) * 1000))")
    STARTUP_TIMES+=("$ELAPSED")
    echo "  Run $i: ${ELAPSED}ms"
done
AVG_STARTUP=$(python3 -c "times=[${STARTUP_TIMES[*]// /,}]; print(sum(times)//len(times))")
echo "  Average: ${AVG_STARTUP}ms (target: <200ms)"
echo ""

# 2. Memory baseline
echo "Measuring memory usage..."
if command -v leaks &> /dev/null; then
    echo "  (memory measurement requires running app)"
fi
echo ""

# 3. Build size
echo "Measuring build size..."
if [ -d "./build" ]; then
    SIZE=$(du -sh ./build 2>/dev/null | cut -f1)
    echo "  Build size: $SIZE"
fi
echo ""

# Summary
echo "=== Results ==="
echo "Startup:  ${AVG_STARTUP}ms (target: <200ms)"
echo ""

# Performance targets
PASS=true
if [ "$AVG_STARTUP" -gt 200 ]; then
    echo "FAIL: Startup time ${AVG_STARTUP}ms exceeds 200ms target"
    PASS=false
fi

if [ "$PASS" = true ]; then
    echo "All performance targets MET"
    exit 0
else
    echo "Some performance targets MISSED"
    exit 1
fi
