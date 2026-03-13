// MARK: - Task Router (Step 16.1)
// Intelligent provider/model routing based on task characteristics.

import Foundation
import Observation

/// Task classification for routing decisions.
public enum TaskType: String, CaseIterable, Sendable {
    case refactoring
    case bugFix
    case feature
    case testGeneration
    case documentation
    case review
    case migration
    case exploration
}

/// A routing suggestion with confidence score.
public struct RoutingSuggestion {
    public let provider: AgentProvider
    public let model: String
    public let confidence: Double
    public let reason: String

    public init(provider: AgentProvider, model: String, confidence: Double, reason: String) {
        self.provider = provider
        self.model = model
        self.confidence = confidence
        self.reason = reason
    }
}

/// Rules-based task classifier.
struct TaskClassifier {
    func classify(_ description: String) -> TaskType {
        let lower = description.lowercased()

        if lower.contains("refactor") || lower.contains("restructure") || lower.contains("reorganize") {
            return .refactoring
        }
        if lower.contains("fix") || lower.contains("bug") || lower.contains("error") || lower.contains("broken") {
            return .bugFix
        }
        if lower.contains("test") || lower.contains("spec") || lower.contains("coverage") {
            return .testGeneration
        }
        if lower.contains("doc") || lower.contains("readme") || lower.contains("comment") {
            return .documentation
        }
        if lower.contains("review") || lower.contains("audit") || lower.contains("check") {
            return .review
        }
        if lower.contains("migrate") || lower.contains("upgrade") || lower.contains("convert") {
            return .migration
        }
        if lower.contains("explore") || lower.contains("research") || lower.contains("investigate") {
            return .exploration
        }
        return .feature
    }
}

/// Configurable routing rules.
struct RoutingRule {
    let taskType: TaskType
    let provider: AgentProvider
    let model: String
    let confidence: Double
    let reason: String
}

/// Tracks user routing choices for learning.
@Observable
final class RoutingHistory {
    private var choices: [(suggested: RoutingSuggestion, chosen: AgentProvider, timestamp: Date)] = []

    func record(suggested: RoutingSuggestion, chosen: AgentProvider) {
        choices.append((suggested: suggested, chosen: chosen, timestamp: Date()))
    }

    /// Returns provider preference override based on user history.
    func preferredProvider(for taskType: TaskType) -> AgentProvider? {
        let recent = choices.suffix(50)
        let overrides = recent.filter { $0.suggested.provider != $0.chosen }

        // If user consistently overrides for certain suggestions, learn from it
        let counts = Dictionary(grouping: overrides) { $0.chosen }
            .mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

/// Main task router — suggests best provider/model for a given task.
@Observable
public final class TaskRouter {

    private let classifier = TaskClassifier()
    private let history = RoutingHistory()

    private var rules: [RoutingRule] = [
        // Deep reasoning tasks → Claude Opus
        RoutingRule(taskType: .refactoring, provider: .claude, model: "opus", confidence: 0.9,
                   reason: "Complex refactoring benefits from deep reasoning"),
        RoutingRule(taskType: .bugFix, provider: .claude, model: "opus", confidence: 0.85,
                   reason: "Bug fixes require careful analysis"),

        // Bulk generation → Claude Sonnet or Codex
        RoutingRule(taskType: .testGeneration, provider: .claude, model: "sonnet", confidence: 0.8,
                   reason: "Test generation is well-suited for fast models"),
        RoutingRule(taskType: .documentation, provider: .claude, model: "sonnet", confidence: 0.85,
                   reason: "Documentation generation works well with fast models"),

        // Review → Gemini or Claude
        RoutingRule(taskType: .review, provider: .gemini, model: "2.5-pro", confidence: 0.75,
                   reason: "Code review with large context window"),

        // Features → Claude Opus
        RoutingRule(taskType: .feature, provider: .claude, model: "opus", confidence: 0.8,
                   reason: "New features benefit from planning capability"),

        // Migration → Aider
        RoutingRule(taskType: .migration, provider: .aider, model: "default", confidence: 0.7,
                   reason: "Aider handles file-level changes well"),

        // Exploration → Claude Sonnet
        RoutingRule(taskType: .exploration, provider: .claude, model: "sonnet", confidence: 0.75,
                   reason: "Exploration needs fast iteration"),
    ]

    public init() {}

    public func suggest(taskDescription: String) -> RoutingSuggestion {
        let taskType = classifier.classify(taskDescription)

        // Check if user has a historical preference
        if let preferred = history.preferredProvider(for: taskType),
           let rule = rules.first(where: { $0.taskType == taskType && $0.provider == preferred }) {
            return RoutingSuggestion(
                provider: rule.provider, model: rule.model,
                confidence: rule.confidence,
                reason: "Based on your previous choices"
            )
        }

        // Fall back to rules
        if let rule = rules.first(where: { $0.taskType == taskType }) {
            return RoutingSuggestion(
                provider: rule.provider, model: rule.model,
                confidence: rule.confidence, reason: rule.reason
            )
        }

        // Default
        return RoutingSuggestion(
            provider: .claude, model: "opus", confidence: 0.5,
            reason: "Default recommendation"
        )
    }

    public func recordChoice(suggested: RoutingSuggestion, chosen: AgentProvider) {
        history.record(suggested: suggested, chosen: chosen)
    }
}
