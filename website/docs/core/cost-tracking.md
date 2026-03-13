---
sidebar_position: 4
---

# Cost Tracking

Multi-level cost aggregation: per-token → per-task → per-session → per-project → fleet-wide.

## Architecture

```
Token Usage → CostEntry → CostEngine → Aggregation
                                ↓
                     session / project / fleet totals
```

## CostEntry

```swift
public struct CostEntry: Codable, Identifiable {
    let provider: AgentProvider
    let model: ModelIdentifier
    let inputTokens: Int
    let outputTokens: Int
    let cost: Decimal
    let timestamp: Date
    let sessionId: String
    let taskId: String?
}
```

## CostEngine

```swift
let engine = CostEngine(persistence: persistence)

// Record costs as they come in
engine.record(entry)

// Query at any level
engine.totalCost(forSession: "session-1")     // $0.45
engine.totalCost(forProject: "my-app")        // $12.30
engine.fleetTotalCost()                        // $47.82

// Analytics
engine.costPerProvider()    // [.claude: $30, .codex: $17]
engine.burnRate(windowMinutes: 60)  // $/hour rate
engine.averageCostPerTask()         // Average task cost
```

## Pricing Model

The `TokenPricing` struct implements per-model pricing:

| Model | Input (per 1M tokens) | Output (per 1M tokens) |
|-------|----------------------|------------------------|
| Claude Opus | $15.00 | $75.00 |
| Claude Sonnet | $3.00 | $15.00 |
| Claude Haiku | $0.25 | $1.25 |
| GPT-4 | $30.00 | $60.00 |
| Gemini Pro | $7.00 | $21.00 |

## Alert Thresholds

```swift
public struct CostAlertConfig {
    let perSession: Decimal   // Default: $10
    let perDay: Decimal       // Default: $50
    let perProject: Decimal   // Default: $100
}
```
