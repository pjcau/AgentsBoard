// MARK: - Verification Chains (Step 16.2)
// Agent A implements → Agent B reviews → Agent C fixes.

import Foundation
import Observation

/// A single step in a verification chain.
public struct ChainStep: Identifiable {
    public let id = UUID()
    public var provider: AgentProvider
    public var model: String
    public var promptTemplate: String
    public var timeout: TimeInterval
    public var requiresApproval: Bool
    public var status: ChainStepStatus = .pending

    public init(provider: AgentProvider, model: String, promptTemplate: String, timeout: TimeInterval, requiresApproval: Bool) {
        self.provider = provider
        self.model = model
        self.promptTemplate = promptTemplate
        self.timeout = timeout
        self.requiresApproval = requiresApproval
    }
}

public enum ChainStepStatus: String, Sendable {
    case pending, running, completed, failed, skipped, awaitingApproval
}

/// A verification chain definition.
public struct VerificationChainDef: Identifiable {
    public let id = UUID()
    public var name: String
    public var steps: [ChainStep]

    public init(name: String, steps: [ChainStep]) {
        self.name = name
        self.steps = steps
    }
}

/// Pre-defined chain templates.
public struct ChainTemplates {
    public static let implementAndReview = VerificationChainDef(
        name: "Implement & Review",
        steps: [
            ChainStep(provider: .claude, model: "opus", promptTemplate: "Implement: {{TASK}}",
                     timeout: 600, requiresApproval: false),
            ChainStep(provider: .claude, model: "sonnet", promptTemplate: "Review the implementation and suggest improvements:\n\n{{PREVIOUS_OUTPUT}}",
                     timeout: 300, requiresApproval: true),
        ]
    )

    public static let implementReviewFix = VerificationChainDef(
        name: "Implement, Review, Fix",
        steps: [
            ChainStep(provider: .claude, model: "opus", promptTemplate: "Implement: {{TASK}}",
                     timeout: 600, requiresApproval: false),
            ChainStep(provider: .gemini, model: "2.5-pro", promptTemplate: "Review this implementation for bugs, edge cases, and improvements:\n\n{{PREVIOUS_OUTPUT}}",
                     timeout: 300, requiresApproval: true),
            ChainStep(provider: .claude, model: "opus", promptTemplate: "Fix the issues found in the review:\n\nReview feedback:\n{{PREVIOUS_OUTPUT}}\n\nOriginal implementation:\n{{STEP_1_OUTPUT}}",
                     timeout: 600, requiresApproval: false),
        ]
    )

    public static let testAndFix = VerificationChainDef(
        name: "Test & Fix",
        steps: [
            ChainStep(provider: .claude, model: "sonnet", promptTemplate: "Write comprehensive tests for: {{TASK}}",
                     timeout: 300, requiresApproval: false),
            ChainStep(provider: .claude, model: "opus", promptTemplate: "Fix any failing tests and ensure all pass:\n\n{{PREVIOUS_OUTPUT}}",
                     timeout: 600, requiresApproval: false),
        ]
    )

    public static var all: [VerificationChainDef] {
        [implementAndReview, implementReviewFix, testAndFix]
    }
}

/// Executes a verification chain step by step.
@Observable
public final class ChainExecutor {

    public var currentStepIndex: Int = 0
    public var stepOutputs: [UUID: String] = [:]
    public var isRunning: Bool = false
    public var chain: VerificationChainDef?

    public var onStepCompleted: ((Int, String) -> Void)?
    public var onChainCompleted: (() -> Void)?
    public var onApprovalNeeded: ((Int) -> Void)?

    public init() {}

    public func execute(chain: VerificationChainDef, task: String) async {
        var mutableChain = chain
        self.chain = mutableChain
        isRunning = true
        currentStepIndex = 0

        for (index, step) in mutableChain.steps.enumerated() {
            currentStepIndex = index
            mutableChain.steps[index].status = .running
            self.chain = mutableChain

            // Build prompt from template
            var prompt = step.promptTemplate.replacingOccurrences(of: "{{TASK}}", with: task)

            // Inject previous output
            if index > 0, let prevOutput = stepOutputs[mutableChain.steps[index - 1].id] {
                prompt = prompt.replacingOccurrences(of: "{{PREVIOUS_OUTPUT}}", with: prevOutput)
            }

            // Inject specific step outputs
            for (i, s) in mutableChain.steps.enumerated() {
                if let output = stepOutputs[s.id] {
                    prompt = prompt.replacingOccurrences(of: "{{STEP_\(i + 1)_OUTPUT}}", with: output)
                }
            }

            // Check if approval needed
            if step.requiresApproval {
                mutableChain.steps[index].status = .awaitingApproval
                self.chain = mutableChain
                onApprovalNeeded?(index)
                // In real impl, would wait for user approval
            }

            // Execute step (in real impl, launches an agent session)
            // For now, mark as completed
            mutableChain.steps[index].status = .completed
            self.chain = mutableChain
            stepOutputs[step.id] = "Output from step \(index + 1)"
            onStepCompleted?(index, "Output from step \(index + 1)")
        }

        isRunning = false
        onChainCompleted?()
    }

    public func approveStep(_ index: Int) {
        guard chain != nil else { return }
        chain?.steps[index].status = .running
    }

    public func skipStep(_ index: Int) {
        guard chain != nil else { return }
        chain?.steps[index].status = .skipped
    }

    public var progress: Double {
        guard let chain, !chain.steps.isEmpty else { return 0 }
        let completed = chain.steps.filter { $0.status == .completed }.count
        return Double(completed) / Double(chain.steps.count)
    }
}
