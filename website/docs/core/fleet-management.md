---
sidebar_position: 3
---

# Fleet Management

Fleet management aggregates all active agent sessions into a single dashboard.

## FleetManaging Protocol

```swift
public protocol FleetManaging: AnyObject {
    var sessions: [any AgentSessionRepresentable] { get }
    var stats: FleetStats { get }
    var onFleetChange: (() -> Void)? { get set }
    func register(_ session: any AgentSessionRepresentable)
    func unregister(sessionId: String)
    func session(byId id: String) -> (any AgentSessionRepresentable)?
}
```

## Fleet Statistics

```swift
public struct FleetStats {
    let totalSessions: Int
    let activeSessions: Int
    let needsInputCount: Int
    let errorCount: Int
    let totalCost: Decimal
    let costByProvider: [AgentProvider: Decimal]
    let sessionsByState: [AgentState: Int]
}
```

## Usage

```swift
let fleet = FleetManager()

// Register sessions as they start
fleet.register(session1)
fleet.register(session2)

// Query fleet state
print("Active: \(fleet.stats.activeSessions)")
print("Total cost: $\(fleet.stats.totalCost)")
print("Needs input: \(fleet.stats.needsInputCount)")

// React to changes
fleet.onFleetChange = {
    updateUI(fleet.stats)
}
```

## Session Representation

Each session in the fleet exposes a read-only view:

```swift
public protocol AgentSessionRepresentable {
    var sessionId: String { get }
    var agentInfo: AgentInfo? { get }
    var state: AgentState { get }
    var totalCost: Decimal { get }
    var projectPath: String? { get }
    var startTime: Date { get }
    var lastEventTime: Date? { get }
}
```
