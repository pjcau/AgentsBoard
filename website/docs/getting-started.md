---
sidebar_position: 1
slug: /getting-started
---

# Getting Started

AgentsBoard is a native macOS application for orchestrating multiple AI coding agents — Claude Code, Codex, Aider, and Gemini — from a single mission-control interface.

## What is AgentsBoard?

Think of it as a **control tower for AI agents**. Instead of juggling multiple terminal windows, AgentsBoard gives you:

- **Fleet view** — see all running agents at a glance with real-time status
- **Cost tracking** — per-session, per-project, and fleet-wide cost aggregation
- **Diff review** — approve or reject file changes with a side-by-side viewer
- **Command palette** — Cmd+K spotlight-style access to every action
- **Session recording** — Asciicast v2 playback for debugging and review
- **MCP server** — JSON-RPC 2.0 interface for external tool integration
- **Context bridge** — share knowledge across agent sessions automatically

## Quick Start

```bash
# Clone the repository
git clone https://github.com/pjcau/AgentsBoard.git
cd AgentsBoard

# Build with Swift Package Manager
swift build

# Run the app
swift run AgentsBoard
```

## Requirements

| Requirement | Version |
|-------------|---------|
| macOS | 14.0 (Sonoma) or later |
| Xcode | 15.0 or later |
| Swift | 5.9 or later |

## Supported AI Agents

| Agent | Status | Detection |
|-------|--------|-----------|
| Claude Code | Full support | Hook events + regex |
| Codex (OpenAI) | Full support | Process detection |
| Aider | Full support | Process detection |
| Gemini | Full support | Process detection |
| Custom | Via protocol | User-defined |

## Next Steps

- [Installation guide](./installation) for detailed setup instructions
- [Architecture overview](./architecture/overview) to understand the system design
- [Core modules](./core/agent-system) to explore each component
