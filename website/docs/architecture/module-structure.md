---
sidebar_position: 3
---

# Module Structure

## Core Modules

```
Sources/Core/
├── Agent/              # Agent detection, state machine, session
├── Activity/           # Structured event timeline
├── Commands/           # Command registry, fuzzy matcher
├── Config/             # 3-level config cascade, YAML parsing
├── Context/            # Cross-session knowledge graph
├── Control/            # Unix socket control server
├── CostTracking/       # Per-token → fleet cost aggregation
├── Fleet/              # Multi-session management
├── Hook/               # Claude Code hook event parsing
├── Keybindings/        # Keyboard shortcut management
├── MCP/                # JSON-RPC 2.0 MCP server
│   └── Tools/          # MCP tool implementations
├── Orchestration/      # Task routing, verification chains
├── Persistence/        # SQLite via GRDB (behind protocol)
├── Project/            # Project discovery and management
├── Recording/          # Asciicast v2 recording engine
├── Rendering/          # Metal GPU terminal rendering
├── Terminal/           # PTY, VT parser, grid, multiplexer
└── Theme/              # Theme engine with hot-reload
```

## UI Modules

```
Sources/UI/
├── CommandPalette/     # Cmd+K spotlight-style palette
├── DiffReview/         # Side-by-side diff viewer
├── DragDrop/           # File attachment handling
├── Editor/             # Syntax-highlighted code viewer
├── FileExplorer/       # Tree-based file browser
├── Launcher/           # Multi-session launcher
├── MenuBar/            # Menu bar extra mode
├── Mermaid/            # Mermaid.js diagram renderer
├── PlanMode/           # Task plan visualization
├── Recording/          # Playback & recording browser
├── Search/             # Cross-session global search
├── Simulator/          # iOS simulator preview
├── VimMode/            # Vim-style navigation
└── WebPreview/         # Embedded web preview
```

## Module Dependencies

```
AgentsBoard (App)
  ├── AgentsBoardCore
  └── AgentsBoardUI
       └── AgentsBoardCore

AgentsBoardCLI
  └── AgentsBoardCore
```

Core has **zero** dependencies on UI. UI depends on Core. App depends on both.
