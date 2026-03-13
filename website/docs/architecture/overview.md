---
sidebar_position: 1
---

# Architecture Overview

AgentsBoard follows a strict **layered architecture** with SOLID principles enforced across every module.

## High-Level Diagram

```
┌─────────────────────────────────────────────┐
│                   App Layer                  │
│  CompositionRoot · KeyEventHandler · @main  │
├─────────────────────────────────────────────┤
│                   UI Layer                   │
│  SwiftUI Views · ViewModels · @Observable   │
├─────────────────────────────────────────────┤
│                  Core Layer                  │
│  Protocols · Domain Logic · Zero UI deps    │
├─────────────────────────────────────────────┤
│              Platform / System               │
│  PTY · Metal · kqueue · Unix Sockets        │
└─────────────────────────────────────────────┘
```

## Target Structure

AgentsBoard is organized as a multi-target Swift Package:

| Target | Type | Dependencies | Purpose |
|--------|------|-------------|---------|
| `AgentsBoard` | Executable | Core, UI | Main app entry point |
| `AgentsBoardCore` | Library | SwiftTerm, Yams, GRDB | Domain logic |
| `AgentsBoardUI` | Library | Core | SwiftUI views |
| `AgentsBoardCLI` | Executable | Core | CLI control tool |

## Key Design Decisions

### Protocol-First Design
Every component is defined as a protocol before implementation. This enables:
- Easy testing with mock implementations
- Swappable implementations without changing consumers
- Clear contracts between modules

### Composition Root Pattern
All concrete type instantiation happens in a single place: `CompositionRoot.swift`. No `init()` calls for services exist outside this file.

### @Observable for State
We use Swift's `@Observable` macro (not Combine) for reactive state management. This gives us:
- Automatic view updates
- No manual subscription management
- Type-safe observation

### Zero UI in Core
The `AgentsBoardCore` target has **zero** dependencies on SwiftUI or AppKit. This ensures domain logic is testable without a UI context.

## Data Flow

```
User Action → View → ViewModel → Core Service → Protocol
                                      ↓
                              Concrete Implementation
                                      ↓
                              State Update (@Observable)
                                      ↓
                              View Re-render (automatic)
```
