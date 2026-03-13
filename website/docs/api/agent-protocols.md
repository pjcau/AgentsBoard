---
sidebar_position: 2
---

# Agent Protocols (ISP)

Four narrow protocols following Interface Segregation Principle.

## AgentDetectable

```swift
public protocol AgentDetectable {
    func detect(command: String, initialOutput: String) -> AgentInfo?
}
```

Returns `AgentInfo` if the process is recognized as an AI agent, `nil` otherwise.

## AgentStateObservable

```swift
public protocol AgentStateObservable: AnyObject {
    var currentState: AgentState { get }
    var onStateChange: ((AgentState, AgentState) -> Void)? { get set }
    func processOutput(_ output: String)
    func processHookEvent(_ event: HookEvent)
}
```

Tracks agent state transitions. Hook events are authoritative; output parsing is fallback.

## AgentCostReportable

```swift
public protocol AgentCostReportable: AnyObject {
    var totalCost: Decimal { get }
    var costEntries: [CostEntry] { get }
    func recordCost(_ entry: CostEntry)
}
```

## AgentControllable

```swift
public protocol AgentControllable {
    func sendInput(_ text: String)
    func approve()
    func reject()
    func terminate()
    func restart()
}
```

## Supporting Types

```swift
public enum AgentState: String, Codable {
    case working, needsInput, error, inactive
}

public enum AgentProvider: String, Codable, CaseIterable {
    case claude, codex, aider, gemini, custom
}

public struct AgentInfo: Codable {
    let provider: AgentProvider
    let model: ModelIdentifier
    let sessionId: String
    let projectPath: String?
    let startTime: Date
    let launchCommand: String
}

public struct ModelIdentifier: Codable {
    let name: String
    let provider: AgentProvider
    let version: String?
}
```
