---
sidebar_position: 3
---

# Fleet Protocols

## FleetManaging

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

## AgentSessionRepresentable

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

## CostAggregating

```swift
public protocol CostAggregating: AnyObject {
    var onCostUpdate: (() -> Void)? { get set }
    func record(_ entry: CostEntry)
    func totalCost(forSession sessionId: String) -> Decimal
    func totalCost(forProject projectId: String) -> Decimal
    func fleetTotalCost() -> Decimal
    func costHistory(from: Date, to: Date) -> [CostEntry]
    func dailyCost(forDate date: Date) -> Decimal
}
```

## ProjectManaging

```swift
public protocol ProjectManaging: AnyObject {
    var projects: [ProjectInfo] { get }
    var onProjectsChange: (() -> Void)? { get set }
    func discover(in directory: String) throws -> [ProjectInfo]
    func add(_ project: ProjectInfo) throws
    func remove(projectId: String) throws
    func project(byId id: String) -> ProjectInfo?
    func project(byPath path: String) -> ProjectInfo?
}
```

## HookEventParsing

```swift
public protocol HookEventParsing {
    func parse(json: Data) throws -> HookEvent
}
```
