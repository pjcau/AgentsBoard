---
sidebar_position: 21
---

# Roadmap

## Completed (v0.1)

### Sprint 1-4: Foundation
- [x] SPM multi-target structure
- [x] SOLID protocol definitions
- [x] PTY process management with forkpty
- [x] VT100 parser (SwiftTerm integration)
- [x] kqueue I/O multiplexer
- [x] Terminal grid with scroll buffer
- [x] Agent detection (Claude, Codex, Aider, Gemini)
- [x] Hook event parsing
- [x] Agent state machine
- [x] Config cascade with YAML
- [x] SQLite persistence (GRDB)

### Sprint 5-6: Core UI
- [x] Metal GPU rendering pipeline
- [x] Glyph atlas for font rendering
- [x] Layout engine (single, list, 2-col, 3-col, fleet)
- [x] Fleet manager with stats aggregation
- [x] Cost engine with per-token pricing
- [x] Activity logger

### Sprint 7-8: Productivity
- [x] Command palette (Cmd+K)
- [x] Fuzzy search matcher
- [x] Keyboard shortcut system
- [x] Vim-mode navigation
- [x] Theme engine (5 built-in themes)
- [x] Menu bar mode

### Sprint 9-12: Review & Analysis
- [x] Diff review (unified + side-by-side)
- [x] File explorer
- [x] Syntax-highlighted editor
- [x] Plan mode visualization
- [x] Web preview
- [x] iOS simulator preview
- [x] Mermaid diagram renderer
- [x] Global search

### Sprint 13-16: Integration
- [x] MCP JSON-RPC 2.0 server
- [x] 5 MCP tools
- [x] Unix socket control server
- [x] agentsctl CLI
- [x] Multi-session launcher
- [x] Session remixer with git worktrees
- [x] Asciicast v2 recording
- [x] Playback view
- [x] Task router
- [x] Verification chains

### Sprint 17-20: Polish
- [x] Drag & drop file attachments
- [x] Context bridge with knowledge graph
- [x] 229 unit tests across 84 suites
- [x] Build scripts and Homebrew cask formula
- [x] Docusaurus documentation

### Sprint 21-24: v0.7.0 Features
- [x] 7-language localization (EN, IT, FR, DE, ES, JA, ZH)
- [x] Session editing (name, provider, command, workdir, branch)
- [x] Activity & Info tabs on session cards
- [x] Resource link detection panel
- [x] Clone & Launch from Git URL
- [x] Session archive, delete, reorder
- [x] Push notifications for needs-input/error
- [x] Font size shortcuts (Cmd+=/Cmd+-/Cmd+0)
- [x] Bottom terminal panel (Cmd+T)
- [x] Appearance mode (Light/Dark/Auto)
- [x] Auto-scroll to selected session
- [x] Metal renderer pipeline (runtime shader compilation)
- [x] TerminalCell compaction (32 -> 16 bytes)
- [x] 29 performance benchmarks

## Future

- [ ] Lazy Terminal (SIGSTOP/SIGCONT for inactive sessions)
- [ ] Live agent provider implementations
- [ ] Collaborative multi-user sessions
- [ ] Plugin system for custom providers
- [ ] Sparkle auto-update
- [ ] App Store distribution
