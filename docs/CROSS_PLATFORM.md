# AgentsBoard Cross-Platform Build Guide

## Architecture

```
┌──────────────────────────────────────────────┐
│            AgentsBoardCore (Swift)            │
│   Agent│Fleet│Cost│MCP│Hooks│Config│Activity  │
└───────┬──────────────┬───────────────┬───────┘
        │              │               │
   (in-process)    (C FFI)         (HTTP)
        │              │               │
        ▼              ▼               ▼
     SwiftUI        Qt/C++        agentsctl
     (macOS)    (Linux+Windows)     (CLI)
```

All desktop frontends link Core Swift **in-process** for maximum performance.
The HTTP server is optional — used only by `agentsctl` CLI and external automation tools.

## macOS (Native SwiftUI)

Full SwiftUI + AppKit + Metal experience.

```bash
# Build and run
swift build && swift run AgentsBoard

# Build .app bundle
bash build.sh
open build/AgentsBoard.app

# Run tests
swift test
```

## Linux (Qt Desktop)

Qt 6.5+ app linking Swift Core as `libagentsboard_core.so` via C FFI.

### Prerequisites

```bash
# Ubuntu 22.04+
sudo apt install qt6-base-dev qt6-declarative-dev cmake ninja-build
sudo apt install libsqlite3-dev

# Install Swift 5.10+
# See https://www.swift.org/install/linux/
```

### Build

```bash
# Step 1: Build Swift Core as shared library
swift build -c release --product AgentsBoardCore

# Step 2: Build Qt app
cd qt
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -G Ninja
ninja

# Step 3: Run
./agentsboard-qt
```

### Docker

```bash
docker compose run build    # Build Core + Qt
docker compose up server    # Run HTTP server (optional)
```

## Windows (Qt Desktop)

Qt 6.5+ app linking Swift Core as `agentsboard_core.dll` via C FFI.

### Prerequisites

- Visual Studio 2022 Build Tools (MSVC)
- Qt 6.5+ (install via Qt Online Installer)
- Swift 5.10+ for Windows
- CMake 3.21+

### Build

```bash
# Step 1: Build Swift Core as shared library
swift build -c release --product AgentsBoardCore

# Step 2: Build Qt app
cd qt
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# Step 3: Run
.\Release\agentsboard-qt.exe
```

## CLI (agentsctl)

Works on all platforms — communicates via HTTP with the optional server.

```bash
# macOS
swift run agentsctl status

# Any platform (with server running)
agentsctl sessions --host localhost --port 19850
agentsctl stats
agentsctl send <session-id> "approve"
agentsctl cost
```

## Dev Helper

```bash
./scripts/dev.sh build    # Platform-aware build
./scripts/dev.sh test     # Platform-aware test
./scripts/dev.sh server   # Start HTTP server (optional)
./scripts/dev.sh qt       # Build and run Qt app
./scripts/dev.sh app      # Build macOS .app
```
