#!/bin/bash
# ============================================================
# AgentsBoard Desktop — Install, run, and show all logs
# Usage: bash scripts/run-desktop.sh
# ============================================================
set -euo pipefail

DEB="release-artifacts/agentsboard-desktop_0.8.0_amd64.deb"
LOG="/tmp/agentsboard-desktop.log"
SERVER_LOG="/tmp/agentsboard-server.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   AgentsBoard Desktop — Run & Debug      ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"

# ----------------------------------------------------------
# 1. Build .deb if missing
# ----------------------------------------------------------
if [ ! -f "$DEB" ]; then
    echo -e "${YELLOW}[1/4] .deb not found, building...${NC}"
    docker build -f Dockerfile.desktop --platform linux/amd64 -o release-artifacts . 2>&1 | tail -20
else
    echo -e "${GREEN}[1/4] .deb found: $DEB${NC}"
fi

# ----------------------------------------------------------
# 2. Install .deb (asks for password if needed)
# ----------------------------------------------------------
echo -e "${YELLOW}[2/4] Installing .deb...${NC}"
sudo dpkg -i "$DEB" 2>&1 || true
sudo apt-get install -f -y 2>&1 || true
echo -e "${GREEN}       Installed.${NC}"

# ----------------------------------------------------------
# 3. Kill any previous instances
# ----------------------------------------------------------
echo -e "${YELLOW}[3/4] Cleaning up previous instances...${NC}"
EXISTING_PID=$(lsof -ti :19850 2>/dev/null || true)
if [ -n "$EXISTING_PID" ]; then
    echo -e "       Killing server on port 19850 (PID $EXISTING_PID)"
    kill "$EXISTING_PID" 2>/dev/null || true
    sleep 0.5
fi
pkill -f agentsboard-tauri 2>/dev/null || true
pkill -f agentsboard-server 2>/dev/null || true
sleep 0.3

# ----------------------------------------------------------
# 4. Launch with full logging
# ----------------------------------------------------------
echo -e "${CYAN}[4/4] Launching AgentsBoard Desktop...${NC}"
echo -e "       App log:    ${LOG}"
echo -e "       Server log: ${SERVER_LOG}"
echo ""

# Prevent Snap library conflicts
unset LD_LIBRARY_PATH 2>/dev/null || true
unset LD_PRELOAD 2>/dev/null || true
unset GTK_PATH 2>/dev/null || true
unset GTK_EXE_PREFIX 2>/dev/null || true
unset GTK_IM_MODULE_FILE 2>/dev/null || true
unset GIO_MODULE_DIR 2>/dev/null || true
unset LOCPATH 2>/dev/null || true
unset GSETTINGS_SCHEMA_DIR 2>/dev/null || true

# Start server with logging
echo -e "${CYAN}--- Starting AgentsBoardServer ---${NC}"
/usr/lib/agentsboard/agentsboard-server 2>&1 | tee "$SERVER_LOG" &
SERVER_PID=$!
echo -e "${GREEN}    Server PID: $SERVER_PID${NC}"

# Wait for server ready
echo -n "    Waiting for server"
for i in $(seq 1 30); do
    if curl -s http://localhost:19850/api/v1/fleet/stats > /dev/null 2>&1; then
        echo -e " ${GREEN}READY${NC}"
        break
    fi
    echo -n "."
    sleep 0.3
done

# Check if server actually started
if ! curl -s http://localhost:19850/api/v1/fleet/stats > /dev/null 2>&1; then
    echo -e " ${RED}FAILED${NC}"
    echo -e "${RED}Server did not start! Last log lines:${NC}"
    tail -20 "$SERVER_LOG"
    echo ""
    echo -e "${YELLOW}Continuing anyway to see Tauri errors...${NC}"
fi

# Start Tauri GUI with logging
echo -e "${CYAN}--- Starting Tauri GUI ---${NC}"
/usr/bin/agentsboard-tauri 2>&1 | tee "$LOG" &
TAURI_PID=$!
echo -e "${GREEN}    Tauri PID: $TAURI_PID${NC}"

# Cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down...${NC}"
    kill "$TAURI_PID" 2>/dev/null || true
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$TAURI_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    echo -e "${GREEN}Done.${NC}"
}
trap cleanup EXIT INT TERM

# Follow both logs interleaved
echo ""
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo -e "${CYAN}  Logs (Ctrl+C to stop)${NC}"
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo ""

tail -f "$SERVER_LOG" "$LOG" 2>/dev/null &
TAIL_PID=$!

# Wait for Tauri to exit (or user Ctrl+C)
wait "$TAURI_PID" 2>/dev/null
EXIT_CODE=$?
kill "$TAIL_PID" 2>/dev/null || true

echo ""
echo -e "${YELLOW}Tauri exited with code: $EXIT_CODE${NC}"
echo -e "Full logs saved to:"
echo -e "  Server: ${SERVER_LOG}"
echo -e "  App:    ${LOG}"
