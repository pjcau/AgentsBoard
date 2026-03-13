# AgentsBoard — AI Agent Mission Control for macOS

## Project Overview

AgentsBoard is a native macOS application that serves as a **Mission Control for AI coding agents**. It combines the best of AgentHub (code review, IDE-lite, orchestration) and Cosmodrome (GPU rendering, fleet management, activity tracking) into a single, high-performance tool that doesn't exist yet.

**Core thesis**: Developers running multiple AI agents need a unified control surface that goes beyond terminal multiplexing — they need fleet visibility, code review in-the-loop, cost tracking, and programmable orchestration, all at native performance.

## Tech Stack

- **Language**: Swift 5.10+
- **UI Framework**: SwiftUI + AppKit
- **Rendering**: Metal (GPU-accelerated terminal rendering)
- **Terminal**: SwiftTerm (with libghostty-vt migration path)
- **Config**: YAML (Yams)
- **Persistence**: SQLite (GRDB.swift)
- **Build**: Xcode / swift build
- **Min target**: macOS 14 (Sonoma)

## SOLID Principles — Mandatory for ALL Code

Every module, protocol, class, and struct in this project MUST adhere to SOLID principles. These are not guidelines — they are hard rules.

### S — Single Responsibility Principle (SRP)
- Every type has ONE reason to change
- A `TerminalSession` manages terminal state — it does NOT parse JSONL, track costs, or render UI
- A `CostTracker` aggregates costs — it does NOT read hook events or display charts
- If a type does two things, split it. No exceptions.
- File naming reflects responsibility: `AgentStateDetector.swift`, not `AgentUtils.swift`

### O — Open/Closed Principle (OCP)
- Modules are **open for extension, closed for modification**
- New AI providers are added by conforming to `AgentProvider` protocol — never by modifying existing provider code
- New themes are added by dropping YAML files — never by editing theme engine code
- New MCP tools are registered via a `MCPToolRegistrable` protocol — never by editing the MCP server core
- Use protocol extensions for shared default behavior

### L — Liskov Substitution Principle (LSP)
- Any `AgentProvider` conformer (ClaudeProvider, CodexProvider, AiderProvider, GeminiProvider) must be interchangeable without breaking fleet management
- Any `CostSource` conformer must produce valid `CostEntry` records regardless of provider
- Any `SessionRecorder` conformer must produce playable recordings regardless of format
- Subtypes must honor the contracts of their supertypes — no surprising overrides

### I — Interface Segregation Principle (ISP)
- Prefer many small protocols over one large one
- `AgentProvider` is split into: `AgentDetectable`, `AgentStateObservable`, `AgentCostReportable`, `AgentControllable`
- UI views depend on narrow view-model protocols, not entire Core types
- A component that only needs to read agent state should not depend on a protocol that also includes session management

### D — Dependency Inversion Principle (DIP)
- Core/ depends on abstractions (protocols), never on concrete UI or system types
- UI/ depends on Core/ protocols, never on concrete Core implementations directly
- All external dependencies (SwiftTerm, GRDB, Yams) are wrapped behind protocols
- Dependency injection via initializer injection — no service locators, no singletons (except App-level composition root)
- The composition root in `App/` wires concrete types to protocols

### SOLID Enforcement Rules
1. **No God objects**: Any type with >200 lines should be reviewed for SRP violations
2. **No switch on provider type**: Use polymorphism via protocols instead
3. **No force-unwrapping**: Use proper error handling or guard statements
4. **Protocol-first design**: Define the protocol BEFORE the implementation
5. **Testability**: If you can't unit-test it in isolation, you violated DIP

## Architecture

```
Sources/
├── App/              # Composition root, window management, lifecycle
│                     # Wires protocols → concrete types (DIP)
├── Core/             # Domain logic, zero UI dependencies
│   ├── Agent/        # Agent detection, state machine, provider abstraction
│   │                 # Protocols: AgentDetectable, AgentStateObservable,
│   │                 #            AgentCostReportable, AgentControllable
│   ├── Terminal/     # PTY management, VT parsing, session lifecycle
│   │                 # Protocol: TerminalSessionManaging
│   ├── Rendering/    # Metal renderer, glyph atlas, viewport scissoring
│   │                 # Protocol: TerminalRenderable
│   ├── Fleet/        # Fleet aggregation, priority sorting, cross-project state
│   │                 # Protocol: FleetManaging
│   ├── Hooks/        # Claude Code hooks, structured JSON events
│   │                 # Protocol: HookEventReceiving
│   ├── MCP/          # JSON-RPC 2.0 server for programmatic control
│   │                 # Protocol: MCPToolRegistrable
│   ├── Config/       # YAML parsing, user/project config, theme loading
│   │                 # Protocol: ConfigProviding
│   ├── Project/      # Project model, session grouping, persistence
│   │                 # Protocol: ProjectManaging
│   ├── CostTracking/ # Per-session, per-task, fleet-wide cost aggregation
│   │                 # Protocol: CostAggregating, CostSource
│   └── Recording/    # Asciicast v2 recording and playback
│                     # Protocol: SessionRecordable
├── UI/               # All SwiftUI views and AppKit bridges
│   ├── SessionMonitor/   # Real-time session cards with embedded terminal
│   ├── FleetOverview/    # Cross-project agent dashboard
│   ├── ActivityLog/      # Structured timeline of agent actions
│   ├── DiffReview/       # Split-pane diff viewer with change requests
│   ├── FileExplorer/     # Project tree browser
│   ├── Editor/           # Syntax-highlighted code editor
│   ├── WebPreview/       # Framework-detecting web preview with live-reload
│   ├── CommandPalette/   # Cmd+K global command interface
│   ├── Themes/           # Theme engine, hot-reload
│   ├── PlanView/         # Plan mode rendering with annotations
│   └── DiagramRenderer/  # Mermaid diagram rendering
└── CLI/              # agentsctl command-line control tool
```

## Agent System — How to Work on This Project

This project is designed to be built by Claude with specialized sub-agents. Each agent has a clear domain.

### Sub-Agent Roles

#### 1. `macos-core` — macOS & System Agent
**Domain**: App lifecycle, Metal rendering, PTY management, kqueue multiplexing, code signing
**Files**: `Sources/App/`, `Sources/Core/Terminal/`, `Sources/Core/Rendering/`
**Skills needed**: Swift, AppKit, Metal, POSIX, kqueue, SwiftTerm
**SOLID focus**: SRP for renderer vs. PTY vs. app lifecycle. OCP via `TerminalRenderable` protocol. DIP — renderer depends on protocol, not SwiftTerm directly.
**Rules**:
- One main thread (UI + Metal), one I/O thread (kqueue)
- No thread-per-session, no Combine, no event bus
- Single MTKView with viewport scissoring for all terminals
- @Observable for state, direct mutation
- Sub-4ms frame target, <5ms input latency
- SwiftTerm wrapped behind `TerminalSessionManaging` protocol

#### 2. `backend-core` — Backend Logic Agent
**Domain**: Agent detection, hooks integration, MCP server, cost tracking, fleet aggregation, recording, config
**Files**: `Sources/Core/Agent/`, `Sources/Core/Hooks/`, `Sources/Core/MCP/`, `Sources/Core/Fleet/`, `Sources/Core/CostTracking/`, `Sources/Core/Recording/`, `Sources/Core/Config/`, `Sources/Core/Project/`
**Skills needed**: Swift, JSON-RPC, Unix sockets, JSONL parsing, SQLite
**SOLID focus**: ISP — split `AgentProvider` into 4 narrow protocols. OCP — new providers via protocol conformance only. DIP — GRDB wrapped behind `PersistenceProviding` protocol.
**Rules**:
- Hooks are authoritative source; regex is fallback only
- Support 4 providers minimum: Claude Code, Codex, Aider, Gemini
- Detect model in use (Opus, Sonnet, GPT-4, Gemini Pro, etc.)
- Cost data must aggregate: per-session → per-project → fleet-wide
- MCP server exposes: list_projects, list_sessions, get_session_content, send_input, get_agent_states, focus_session, start/stop_recording, get_fleet_stats, get_activity_log
- Zero Core/ dependencies on UI/
- Every provider is a separate type conforming to provider protocols
- No switch/case on provider type anywhere — use polymorphism

#### 3. `frontend-ui` — Frontend & UI Agent
**Domain**: All SwiftUI views, layout system, command palette, themes, diff review, file explorer, editor
**Files**: `Sources/UI/`
**Skills needed**: SwiftUI, AppKit bridging, syntax highlighting, diff rendering, Mermaid.js
**SOLID focus**: SRP — each view has ONE job. DIP — views depend on view-model protocols from Core, not concrete types. ISP — views consume only the protocol slices they need.
**Rules**:
- Views consume @Observable models from Core — no business logic in views
- Support layouts: Single, List, 2-Column, 3-Column, Focus
- Diff review must support: split-pane, inline comments, batch feedback, approve/reject
- Plan view: markdown rendering + line-level annotation
- Command palette: Cmd+K for sessions/repos/actions, Cmd+P for files
- Themes: YAML-based, hot-reload from ~/Library/Application Support/AgentsBoard/themes/
- All keyboard shortcuts must be configurable

### Cross-Cutting Rules (ALL agents must follow)

1. **SOLID always**: Every type, every protocol, every module. No exceptions.
2. **Minimal dependencies**: Only SwiftTerm, Yams, GRDB.swift. Justify any addition.
3. **No Electron, no web views** (except WebPreview for user's dev servers)
4. **Performance budgets**: <200ms startup, <5ms input latency, <4ms frame render, <10MB per session
5. **Privacy**: 100% local, zero telemetry, zero network calls (except user's dev servers)
6. **Provider-agnostic Core**: Agent/ must abstract providers behind protocols
7. **Test everything in Core/**: Unit tests for all Core/ modules. Mock via protocol conformance.
8. **Config paths**:
   - Project: `agentsboard.yml` in project root
   - User: `~/.config/agentsboard/config.yml`
   - State: `~/Library/Application Support/AgentsBoard/`
   - Themes: `~/Library/Application Support/AgentsBoard/themes/`
9. **Git conventions**: Conventional commits, one feature per PR
10. **Protocol-first**: Define protocol → write tests against protocol → implement concrete type

## Key Design Decisions

- **Review-in-the-loop**: Unlike any competitor, agents' file changes can be reviewed, annotated, and approved/rejected BEFORE being applied. This is the core differentiator.
- **Fleet-first**: The default view is fleet overview, not a single session. We assume developers run 3-10 agents simultaneously.
- **Programmable**: MCP server + CLI means AgentsBoard can be controlled by other agents, enabling meta-orchestration.
- **Record everything**: Every session can be recorded for post-mortems, demos, or onboarding.

## Commands

```bash
# Build
swift build

# Run tests
swift test

# Build DMG
bash scripts/bundle.sh

# Run CLI tool
swift run agentsctl
```
