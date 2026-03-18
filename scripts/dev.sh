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
  qt       Build and run Qt desktop app (Linux/Windows)
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

cmd_qt() {
    # Build Swift Core as shared library
    echo "Building Swift Core..."
    swift build -c release --product AgentsBoardCore

    # Build Qt app
    echo "Building Qt app..."
    cd "$PROJECT_DIR/qt"
    mkdir -p build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    cmake --build .

    echo "Running AgentsBoard Qt..."
    ./agentsboard-qt
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
    qt)     cmd_qt ;;
    app)    cmd_app ;;
    *)      usage ;;
esac
