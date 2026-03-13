---
sidebar_position: 20
---

# Contributing

## Development Setup

```bash
git clone https://github.com/pjcau/AgentsBoard.git
cd AgentsBoard
swift build
swift test
```

## Code Style

- **Protocol-first**: define the protocol, then implement
- **SOLID everywhere**: see [SOLID Principles](./architecture/solid-principles)
- **Public API**: all Core types must be `public` for cross-module access
- **@Observable**: use Swift's `@Observable` macro, not Combine
- **No UI in Core**: `AgentsBoardCore` has zero UI dependencies

## Running Tests

```bash
# All tests
swift test

# Specific test suite
swift test --filter AgentsBoardCoreTests

# With verbose output
swift test -v
```

## Project Layout

| Directory | What goes here |
|-----------|---------------|
| `Sources/Core/` | Domain logic, protocols, models |
| `Sources/UI/` | SwiftUI views, view models |
| `Sources/App/` | App entry point, CompositionRoot |
| `Sources/CLI/` | agentsctl commands |
| `Tests/CoreTests/` | Core unit tests |
| `Tests/UITests/` | UI view model tests |

## Pull Requests

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure `swift build` and `swift test` pass
5. Submit a pull request
