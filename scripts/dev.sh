#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

usage() {
    cat <<EOF
AgentsBoard development helper

USAGE:
  ./scripts/dev.sh <command>

COMMANDS:
  build    Build the project (macOS: swift build / Linux: docker compose)
  test     Run tests (macOS: swift test / Linux: docker compose)
  server   Start AgentsBoardServer on localhost:19850
  web      Start web frontend dev server (cd web && npm run dev)
  tauri    Start Tauri dev (server + tauri dev)
  app      Build macOS .app bundle (macOS only)

EOF
}

cmd_build() {
    if is_macos; then
        swift build
    else
        docker compose run --rm build
    fi
}

cmd_test() {
    if is_macos; then
        swift test
    else
        docker compose run --rm test
    fi
}

cmd_server() {
    if is_macos; then
        swift run AgentsBoardServer
    else
        docker compose up server
    fi
}

cmd_web() {
    cd "$PROJECT_DIR/web"
    npm run dev
}

cmd_tauri() {
    # Start server in background
    cmd_server &
    SERVER_PID=$!
    trap "kill $SERVER_PID 2>/dev/null" EXIT

    cd "$PROJECT_DIR/tauri"
    cargo tauri dev
}

cmd_app() {
    if ! is_macos; then
        echo "Error: .app bundle can only be built on macOS"
        exit 1
    fi
    bash "$PROJECT_DIR/build.sh"
}

case "${1:-}" in
    build)  cmd_build ;;
    test)   cmd_test ;;
    server) cmd_server ;;
    web)    cmd_web ;;
    tauri)  cmd_tauri ;;
    app)    cmd_app ;;
    *)      usage ;;
esac
