---
sidebar_position: 8
---

# Orchestration

Task routing, verification chains, and session remixing for multi-agent workflows.

## Task Router

Automatically suggests the best agent/model for a given task:

```swift
let router = TaskRouter()
let suggestion = router.suggest(taskDescription: "Fix the auth bug and add tests")
// → RoutingSuggestion(provider: .claude, model: "opus", confidence: 0.85)
```

### Task Types

```swift
public enum TaskType {
    case refactoring, bugFix, feature, testGeneration
    case documentation, review, migration, exploration
}
```

## Verification Chains

Multi-step workflows where agents review each other's work:

```swift
// Built-in chain templates
let chain = ChainTemplates.implementAndReview
// Step 1: Claude Opus implements
// Step 2: Different agent reviews

let chain = ChainTemplates.implementReviewFix
// Step 1: Implement
// Step 2: Review
// Step 3: Fix issues found

let chain = ChainTemplates.testAndFix
// Step 1: Write tests
// Step 2: Fix failing tests
```

### Chain Execution

```swift
let executor = ChainExecutor()
executor.onStepCompleted = { index, output in ... }
executor.onApprovalNeeded = { index in ... }
executor.onChainCompleted = { success in ... }

await executor.execute(chain: chain, task: "Refactor the payment module")
```

## Session Remixing

Transfer context from one agent session to another:

```swift
let remixer = SessionRemixer()
let result = try await remixer.remix(config: .init(
    sourceSession: "session-1",
    targetProvider: .codex,
    branchName: "feature/remix",
    contextDepth: .summary,
    projectPath: "/path/to/project"
))
// Creates a git worktree and starts a new session with extracted context
```
