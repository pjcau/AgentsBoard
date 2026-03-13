---
sidebar_position: 9
---

# Context Bridge

Cross-session knowledge sharing with temporal decay.

## Knowledge Graph

Each project maintains a knowledge graph that captures decisions, patterns, and conventions discovered during agent sessions:

```swift
let bridge = ContextBridge(persistence: persistence)
let graph = bridge.graph(for: "my-project")

// Add knowledge
graph.add(KnowledgeEntry(
    type: .decision,
    content: "Using JWT tokens with 24h expiry for auth",
    sourceSessionId: "session-1"
))

// Query by type
let decisions = graph.query(type: .decision, limit: 10)

// Get relevant context for a new task
let context = graph.relevantContext(for: "authentication", tokenBudget: 2000)
```

## Knowledge Types

```swift
public enum KnowledgeType {
    case decision      // Architectural decisions
    case pattern       // Code patterns discovered
    case bug           // Bugs found and fixed
    case fileImportant // Important files identified
    case convention    // Coding conventions
    case dependency    // Dependency information
}
```

## Temporal Decay

Knowledge entries decay over time — older entries get lower relevance scores. This ensures that recent discoveries are prioritized over stale information.

## Context Injection

When starting a new agent session, the bridge can generate a context prefix:

```swift
let prefix = bridge.contextPrefix(for: "my-project", task: "Add OAuth support")
// Returns a summary of relevant past decisions and patterns
// that the new agent session should know about
```

## Pipeline

```
Agent Output → KnowledgeExtractor → KnowledgeGraph → ContextInjector → New Session
```

The `KnowledgeExtractor` parses agent output for:
- Architecture decisions
- File modifications
- Error patterns
- Convention discoveries
