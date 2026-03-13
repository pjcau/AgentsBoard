---
sidebar_position: 2
---

# SOLID Principles

Every module in AgentsBoard enforces SOLID principles. Here's how each principle is applied.

## Single Responsibility (SRP)

Each class has one reason to change:

| Class | Responsibility |
|-------|---------------|
| `PTYProcess` | Fork and manage a single PTY |
| `VTParser` | Parse VT100 escape sequences |
| `CostEngine` | Aggregate cost data |
| `FleetManager` | Track active sessions |
| `RecordingEngine` | Write Asciicast v2 files |

## Open/Closed (OCP)

New functionality is added through extension, not modification:

```swift
// New agent providers are added by conforming to protocols
// No existing code needs to change
public protocol AgentDetectable {
    func detect(command: String, initialOutput: String) -> AgentInfo?
}

// Register at runtime
registry.register(myNewDetector)
```

**OCP in practice:**
- `ProviderRegistry` — register new agent detectors without modifying existing code
- `CommandRegistry` — add commands via `CommandProviding` protocol
- `MCPServer` — register new tools at runtime
- `ThemeEngine` — add themes without touching existing ones

## Liskov Substitution (LSP)

All protocol implementations are fully substitutable:

```swift
// Any FleetManaging implementation works here
func showStats(fleet: any FleetManaging) {
    let stats = fleet.stats
    print("Active: \(stats.activeSessions)")
}
```

## Interface Segregation (ISP)

Agent capabilities are split into 4 narrow protocols instead of one large one:

```swift
public protocol AgentDetectable { ... }      // Detection
public protocol AgentStateObservable { ... } // State tracking
public protocol AgentCostReportable { ... }  // Cost reporting
public protocol AgentControllable { ... }    // Control actions
```

A simple agent might only implement `AgentDetectable`, while a full-featured one implements all four.

## Dependency Inversion (DIP)

High-level modules depend on abstractions, not concretions:

```swift
// Core defines the protocol
public protocol PersistenceProviding {
    func save<T: Codable & Identifiable>(_ record: T, in table: String) throws
    func fetch<T: Codable & Identifiable>(from table: String, id: String) throws -> T?
    // ...
}

// Implementation uses GRDB (but Core doesn't know about GRDB)
final class DatabaseManager: PersistenceProviding { ... }

// CompositionRoot wires them together
let persistence: any PersistenceProviding = DatabaseManager()
```

**DIP wrappers:**
- `PersistenceProviding` wraps GRDB/SQLite
- `YAMLParsing` wraps Yams
- `TerminalSessionManaging` wraps SwiftTerm + PTY
- `ThemeProviding` wraps the theme engine
