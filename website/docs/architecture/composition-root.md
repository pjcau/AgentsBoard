---
sidebar_position: 4
---

# Composition Root

The Composition Root is the **single place** where all concrete implementations are instantiated and wired together. This is the cornerstone of Dependency Inversion.

## Location

`Sources/App/CompositionRoot.swift`

## How It Works

```swift
@Observable
final class CompositionRoot {
    // All services exposed as protocol types
    private(set) var configProvider: any ConfigProviding
    private(set) var themeProvider: any ThemeProviding
    private(set) var persistence: any PersistenceProviding
    private(set) var fleetManager: any FleetManaging
    private(set) var costAggregator: any CostAggregating
    private(set) var projectManager: any ProjectManaging
    private(set) var hookEventParser: any HookEventParsing
    private(set) var recorder: any SessionRecordable

    init() {
        // Phase 1: Infrastructure (no dependencies)
        let persistence = DatabaseManager()
        self.persistence = persistence

        // Phase 2: Configuration
        let configProvider = ConfigManager(yamlParser: YAMLParserImpl())
        self.configProvider = configProvider

        // Phase 3: Domain services
        self.fleetManager = FleetManager()
        self.costAggregator = CostEngine(persistence: persistence)
        // ... etc
    }
}
```

## Initialization Phases

Services are initialized in dependency order:

1. **Infrastructure** — persistence, YAML parser (no dependencies)
2. **Configuration** — config manager (depends on YAML parser)
3. **Domain Services** — fleet, cost, project, recording (depend on persistence + config)
4. **Integration** — hook parser, MCP server (depend on domain services)

## Rules

- **Only `CompositionRoot` creates concrete types** — everywhere else uses protocols
- **No service locator pattern** — dependencies are injected, not looked up
- **`@Observable`** — the root itself is observable for SwiftUI environment injection
- **Stubs for incremental development** — unimplemented services use stub implementations that compile but throw at runtime
