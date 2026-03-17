# Changelog

## v0.8.0 (2026-03-17)

Install:
- **macOS**: `brew tap pjcau/agentsboard && brew install --cask agentsboard`
- **Linux**: Download `AgentsBoard-0.8.0-linux-arm64.tar.gz` from Releases
- **Web**: Download `AgentsBoard-0.8.0-web.tar.gz` and serve with any HTTP server
- **Docker**: `docker run -p 19850:19850 agentsboard-ubuntu`

### Cross-Platform Architecture
- **HTTP + WebSocket API Server**: New `AgentsBoardServer` executable powered by Hummingbird 2.0. REST API at `localhost:19850/api/v1` exposes sessions, fleet stats, activity, costs, config, themes, and terminal output.
- **WebSocket real-time events**: Event broker with channels (`fleet`, `session:{id}`, `activity`, `costs`) for live updates to connected clients.
- **Platform guards**: Core module compiles on Linux with `#if canImport` guards on Metal, AppKit, SwiftTerm, and UserNotifications. NullRenderer and VTParserStub for non-macOS platforms.
- **Conditional Package.swift**: SwiftTerm dependency is macOS-only. New `AgentsBoardServer` target depends on Hummingbird (cross-platform).
- **Web frontend**: React 18 + TypeScript + Vite app with xterm.js (WebGL) terminal, fleet overview, session list, activity log, and cost dashboard. Connects to server via REST + WebSocket.
- **Tauri desktop app**: Wraps web frontend for Linux and Windows. Launches Swift server as sidecar process. System tray with fleet status.
- **Docker support**: Dockerfile (Swift 5.10 on Ubuntu Noble), docker-compose.yml with build/test/server services.
- **Unified dev script**: `scripts/dev.sh` with commands: build, test, server, web, tauri, app.
- **Embedded server**: macOS app can optionally run the HTTP server embedded (configurable in Settings), sharing Core instances between native UI and API.
- **CLI via HTTP**: `agentsctl` now uses HTTP API instead of Unix sockets. Supports `--host` and `--port` flags. New commands: `config`, `themes`.
- **CI/CD**: GitHub Actions matrix — macOS (full build), Linux (Docker), web (npm), Tauri (Linux + Windows).
- **Linux packaging**: `scripts/package-linux.sh` generates .deb package.

### Deprecations
- `ControlServer` (Unix socket) deprecated in favor of HTTP API. Will be removed in v0.9.0.

### New Dependencies
- **Hummingbird 2.0**: Async HTTP server (~8 transitive deps)
- **hummingbird-websocket 2.0**: WebSocket upgrade support

## v0.7.0 (2026-03-16)

Install: `brew tap pjcau/agentsboard && brew install --cask agentsboard`

### New Features
- **Localization**: 7 languages — English, Italian, French, German, Spanish, Japanese, Simplified Chinese. Auto-detects device locale with English fallback. 148 localized strings across all UI.
- **Session editing**: Edit session name, provider, command, working directory, and git branch from both the session card header (pencil icon) and sidebar context menu.
- **Activity & Info tabs**: Session cards now have 4 tabs — Terminal, Activity (timestamped state changes), Info (provider/model/session/project details), and Files.
- **Resource Links panel**: Collapsible bottom panel on each session card showing URLs detected in terminal output, with context-aware icons (GitHub, docs, StackOverflow, npm, Slack, Jira) and click-to-open.
- **Clone & Launch**: Clone a Git repository from URL (HTTPS or SSH) directly from the session launcher, with auto-detection of repo name and provider.
- **Session archive & delete**: Archive sessions (hidden but preserved) or delete them (with confirmation dialog). Toggle "Show Archived" in sidebar.
- **Session reordering**: Move sessions up/down via sidebar context menu. Order persisted in FleetManager.
- **Push notifications**: macOS native notifications when an agent enters `.needsInput` or `.error` state. 30-second cooldown per session.
- **Font size shortcuts**: Cmd+= / Cmd+- / Cmd+0 to increase/decrease/reset terminal font size (8-28pt, persisted).
- **Bottom terminal panel**: Slide-up terminal (Cmd+T) at 1/4 window height for quick shell access.
- **Appearance mode**: Light/Dark/Auto mode picker in toolbar.
- **Auto-scroll to selected session**: When clicking a session in sidebar, the grid scrolls to show it.

### Performance
- **Metal renderer pipeline**: Implemented setupPipeline() with runtime shader compilation, direct MTLBuffer writes (zero per-frame allocations), per-viewport scissor rects.
- **TerminalCell compaction**: 32 bytes -> 16 bytes (50% memory reduction). UInt32 codepoint + packed colors.
- **Deferred terminal start**: PTY process starts on next run loop tick after SwiftUI layout, fixing zero-column terminal bug.
- **Grid layout min-width enforcement**: Cards auto-reduce column count when too narrow (min 350px).
- **29 performance benchmarks**: Covering vertex generation, triple buffering, viewport scissoring, kqueue, grid ops, input latency, startup, and memory budgets.

### Bug Fixes
- Fix launcher not closing after pressing Launch button (SwiftUI .sheet blocking NSWindow dismiss)
- Fix terminal not filling card width (PTY started with frame .zero)
- Fix debug button spawning 100 real PTY processes (now gated by command check)
- Fix placeholder sessions showing "Waiting for output" instead of "No output"
- Fix `defaultCommand` access level for cross-module usage

### Documentation
- CLAUDE.md synced with all new features, commands, and architecture
- Performance report updated with 224 test count
- Full architecture map with 17 Core modules and 23 UI directories

---

## v0.6.2 (2026-03-14)

### Features
- Ad-hoc code signing for Gatekeeper bypass
- E2E test improvements: batch launch, layout identifiers, scroll tests

---

## v0.6.0 (2026-03-14)

### Features
- Initial public release
- Multi-session launcher with Smart Mode
- Fleet overview dashboard
- Session monitoring with SwiftTerm terminal emulator
- Diff review with approve/reject
- Command palette (Cmd+K)
- File explorer
- Activity log
- Cost tracking
- kqueue-based I/O multiplexer for 50+ sessions
- Metal GPU rendering infrastructure
- Status bar widget with per-provider cost breakdown
- Mermaid diagram rendering
- Recording playback
- Worktree manager
