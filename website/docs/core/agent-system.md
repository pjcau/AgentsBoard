---
sidebar_position: 1
---

# Agent System

The agent system is the heart of AgentsBoard — it detects, tracks, and controls AI coding agents.

## ISP: Four Narrow Protocols

Instead of one monolithic interface, agent capabilities are split into four protocols:

### AgentDetectable
Detects which AI agent is running from process command and initial output.

```swift
public protocol AgentDetectable {
    func detect(command: String, initialOutput: String) -> AgentInfo?
}
```

### AgentStateObservable
Tracks real-time agent state transitions (working, needs input, error, inactive).

```swift
public protocol AgentStateObservable: AnyObject {
    var currentState: AgentState { get }
    var onStateChange: ((AgentState, AgentState) -> Void)? { get set }
    func processOutput(_ output: String)
    func processHookEvent(_ event: HookEvent)
}
```

### AgentCostReportable
Reports cost data per agent session.

```swift
public protocol AgentCostReportable: AnyObject {
    var totalCost: Decimal { get }
    var costEntries: [CostEntry] { get }
    func recordCost(_ entry: CostEntry)
}
```

### AgentControllable
Sends input and control signals to agent sessions.

```swift
public protocol AgentControllable {
    func sendInput(_ text: String)
    func approve()
    func reject()
    func terminate()
    func restart()
}
```

## Supported Providers

```swift
public enum AgentProvider: String, Codable, CaseIterable {
    case claude, codex, aider, gemini, custom
}
```

## Provider Registry (OCP)

New providers are registered at runtime without modifying existing code:

```swift
let registry = ProviderRegistry()
registry.register(ClaudeDetector())
registry.register(CodexDetector())
registry.register(MyCustomDetector())

// Detection tries each registered detector in order
let info = registry.detect(command: "claude", initialOutput: "...")
```

## Agent State Machine

The `AgentStateMachine` processes output and hook events to determine the current agent state:

```
inactive → working → needsInput → working → inactive
              ↓
           error → inactive
```

Hook events from Claude Code are the **authoritative source**; regex parsing is the fallback.
