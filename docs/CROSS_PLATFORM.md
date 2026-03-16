# AgentsBoard Cross-Platform Build Guide

## Architecture

```
┌──────────────────────────────────────────────┐
│            AgentsBoardCore (Swift)            │
│   Agent│Fleet│Cost│MCP│Hooks│Config│Activity  │
│                                              │
│   AgentsBoardServer (Hummingbird HTTP+WS)    │
│         REST /api/v1/* + WebSocket           │
│              localhost:19850                  │
└──────────────────┬───────────────────────────┘
        ┌──────────┼──────────┬──────────┐
        ▼          ▼          ▼          ▼
   SwiftUI      Tauri       Web       agentsctl
   (macOS)   (Linux+Win)  (browser)    (CLI)
```

## macOS (Native)

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

## Linux

Headless server + Tauri desktop app.

### Option A: Docker

```bash
# Build
docker compose run build

# Run server
docker compose up server

# Test
docker compose run test
```

### Option B: Native Swift

```bash
# Install Swift 5.10+ and SQLite
sudo apt install libsqlite3-dev

# Build server
swift build --target AgentsBoardServer -c release

# Run
.build/release/AgentsBoardServer
```

### Option C: Tauri App

```bash
# Prerequisites: Node.js 20+, Rust, Tauri CLI
cd web && npm ci && cd ..
cd tauri && cargo tauri build
```

## Windows

Via Tauri only.

```bash
# Prerequisites: Node.js 20+, Rust, Visual Studio Build Tools
cd web && npm ci && cd ..
cd tauri && cargo tauri build
```

## Web (Browser)

```bash
cd web
npm install
npm run dev     # Dev server at http://localhost:5173
npm run build   # Production build to web/dist/
```

Requires AgentsBoardServer running on localhost:19850.

## CLI (agentsctl)

Works on all platforms — communicates via HTTP.

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
./scripts/dev.sh server   # Start HTTP server
./scripts/dev.sh web      # Start web dev server
./scripts/dev.sh tauri    # Start Tauri dev
./scripts/dev.sh app      # Build macOS .app
```
