// MARK: - Orchestration Tests (TaskRouter, VerificationChain, SessionRemixer)

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - TaskType Tests

@Suite("TaskType")
struct TaskTypeTests {
    @Test func allTypes() {
        let types: [TaskType] = [
            .refactoring, .bugFix, .feature, .testGeneration,
            .documentation, .review, .migration, .exploration
        ]
        #expect(types.count == 8)
    }
}

// MARK: - TaskRouter Tests

@Suite("TaskRouter")
struct TaskRouterTests {
    @Test func suggestReturnsResult() {
        let router = TaskRouter()
        let suggestion = router.suggest(taskDescription: "Fix the login bug")
        #expect(!suggestion.reason.isEmpty)
        #expect(suggestion.confidence > 0)
    }

    @Test func suggestForDifferentTasks() {
        let router = TaskRouter()
        let bugSuggestion = router.suggest(taskDescription: "Fix the crash in authentication")
        let docSuggestion = router.suggest(taskDescription: "Write API documentation")
        #expect(bugSuggestion.confidence > 0)
        #expect(docSuggestion.confidence > 0)
    }
}

// MARK: - RoutingSuggestion Tests

@Suite("RoutingSuggestion")
struct RoutingSuggestionTests {
    @Test func creation() {
        let suggestion = RoutingSuggestion(
            provider: .claude, model: "opus",
            confidence: 0.9, reason: "Best for complex tasks"
        )
        #expect(suggestion.provider == .claude)
        #expect(suggestion.model == "opus")
        #expect(suggestion.confidence == 0.9)
        #expect(suggestion.reason == "Best for complex tasks")
    }
}

// MARK: - ChainStep Tests

@Suite("ChainStep")
struct ChainStepTests {
    @Test func creation() {
        let step = ChainStep(
            provider: .claude, model: "opus",
            promptTemplate: "Review the code",
            timeout: 300, requiresApproval: true
        )
        #expect(step.provider == .claude)
        #expect(step.model == "opus")
        #expect(step.promptTemplate == "Review the code")
        #expect(step.timeout == 300)
        #expect(step.requiresApproval)
        #expect(step.status == .pending)
    }
}

// MARK: - ChainStepStatus Tests

@Suite("ChainStepStatus")
struct ChainStepStatusTests {
    @Test func allStatuses() {
        let statuses: [ChainStepStatus] = [
            .pending, .running, .completed, .failed, .skipped, .awaitingApproval
        ]
        #expect(statuses.count == 6)
    }
}

// MARK: - ChainTemplates Tests

@Suite("ChainTemplates")
struct ChainTemplatesTests {
    @Test func implementAndReview() {
        let chain = ChainTemplates.implementAndReview
        #expect(chain.name == "Implement & Review")
        #expect(chain.steps.count >= 2)
    }

    @Test func implementReviewFix() {
        let chain = ChainTemplates.implementReviewFix
        #expect(chain.name.contains("Review"))
        #expect(chain.steps.count >= 3)
    }

    @Test func testAndFix() {
        let chain = ChainTemplates.testAndFix
        #expect(chain.name == "Test & Fix")
        #expect(chain.steps.count >= 2)
    }

    @Test func allStepsPending() {
        let chain = ChainTemplates.implementAndReview
        for step in chain.steps {
            #expect(step.status == .pending)
        }
    }
}

// MARK: - ChainExecutor Tests

@Suite("ChainExecutor")
struct ChainExecutorTests {
    @Test func initialState() {
        let executor = ChainExecutor()
        #expect(!executor.isRunning)
        #expect(executor.currentStepIndex == 0)
        #expect(executor.stepOutputs.isEmpty)
    }

    @Test func progress() {
        let executor = ChainExecutor()
        #expect(executor.progress == 0)
    }
}

// MARK: - ContextDepth Tests

@Suite("ContextDepth")
struct ContextDepthTests {
    @Test func allDepths() {
        let depths: [ContextDepth] = [.summary, .lastNActions, .fullTranscript]
        #expect(depths.count == 3)
    }
}

// MARK: - SessionContext Tests

@Suite("SessionContext")
struct SessionContextTests {
    @Test func emptyInit() {
        let ctx = SessionContext()
        #expect(ctx.sessionId.isEmpty)
        #expect(ctx.summary.isEmpty)
        #expect(ctx.filesModified.isEmpty)
        #expect(ctx.keyDecisions.isEmpty)
        #expect(ctx.errors.isEmpty)
    }

    @Test func mutability() {
        var ctx = SessionContext()
        ctx.sessionId = "s1"
        ctx.provider = .claude
        ctx.summary = "Built auth module"
        ctx.filesModified = ["auth.swift"]
        ctx.keyDecisions = ["Used JWT"]
        #expect(ctx.sessionId == "s1")
        #expect(ctx.provider == .claude)
        #expect(ctx.filesModified.count == 1)
    }
}
