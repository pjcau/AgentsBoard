// MARK: - Cost Engine (Step 4.3)
// Aggregates costs: per-token → per-task → per-session → per-project → fleet-wide.

import Foundation
import Observation

@Observable
public final class CostEngine: CostAggregating {

    // MARK: - Properties

    public var onCostUpdate: (() -> Void)?

    private var entries: [CostEntry] = []
    private let persistence: any PersistenceProviding
    private let alertThresholds: CostAlertConfig

    // MARK: - Init

    public init(persistence: any PersistenceProviding, alertThresholds: CostAlertConfig = .default) {
        self.persistence = persistence
        self.alertThresholds = alertThresholds
    }

    // MARK: - CostAggregating

    public func record(_ entry: CostEntry) {
        entries.append(entry)
        try? persistence.save(entry, in: "cost_entries")
        checkAlerts(for: entry)
        onCostUpdate?()
    }

    public func totalCost(forSession sessionId: String) -> Decimal {
        entries.filter { $0.sessionId == sessionId }.reduce(0) { $0 + $1.cost }
    }

    public func totalCost(forProject projectId: String) -> Decimal {
        // Would need session → project mapping; simplified for now
        entries.reduce(0) { $0 + $1.cost }
    }

    public func fleetTotalCost() -> Decimal {
        entries.reduce(0) { $0 + $1.cost }
    }

    public func costHistory(from startDate: Date, to endDate: Date) -> [CostEntry] {
        entries.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    public func dailyCost(forDate date: Date) -> Decimal {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return costHistory(from: start, to: end).reduce(0) { $0 + $1.cost }
    }

    // MARK: - Statistics

    public func costPerProvider() -> [AgentProvider: Decimal] {
        var result: [AgentProvider: Decimal] = [:]
        for entry in entries {
            result[entry.provider, default: 0] += entry.cost
        }
        return result
    }

    public func averageCostPerTask() -> Decimal {
        let tasks = Set(entries.compactMap(\.taskId))
        guard !tasks.isEmpty else { return 0 }
        return fleetTotalCost() / Decimal(tasks.count)
    }

    public func burnRate(windowMinutes: Int = 60) -> Decimal {
        let cutoff = Date().addingTimeInterval(-TimeInterval(windowMinutes * 60))
        let recentCost = entries.filter { $0.timestamp >= cutoff }.reduce(0) { $0 + $1.cost }
        return recentCost
    }

    // MARK: - Alerts

    private func checkAlerts(for entry: CostEntry) {
        let sessionCost = totalCost(forSession: entry.sessionId)
        if sessionCost > alertThresholds.perSession {
            // Would trigger notification — integrated in Sprint 6
        }

        let dailyTotal = dailyCost(forDate: Date())
        if dailyTotal > alertThresholds.perDay {
            // Would trigger notification
        }
    }
}

// MARK: - Cost Alert Config

public struct CostAlertConfig: Sendable {
    public let perSession: Decimal
    public let perDay: Decimal
    public let perProject: Decimal

    public init(perSession: Decimal, perDay: Decimal, perProject: Decimal) {
        self.perSession = perSession
        self.perDay = perDay
        self.perProject = perProject
    }

    public static let `default` = CostAlertConfig(
        perSession: 10,
        perDay: 50,
        perProject: 100
    )
}

// MARK: - Pricing Models (Step 4.3)

public protocol PricingModel {
    func calculateCost(inputTokens: Int, outputTokens: Int, model: ModelIdentifier) -> Decimal
}

public struct TokenPricing: PricingModel {
    // Prices per million tokens (as of March 2026)
    private let prices: [String: (input: Decimal, output: Decimal)] = [
        "claude-opus-4-6": (15, 75),
        "claude-sonnet-4-6": (3, 15),
        "claude-haiku-4-5": (0.8, 4),
        "gpt-4": (10, 30),
        "o4-mini": (1.1, 4.4),
        "gemini-2.5-pro": (1.25, 10),
        "gemini-2.5-flash": (0.15, 0.6),
    ]

    public init() {}

    public func calculateCost(inputTokens: Int, outputTokens: Int, model: ModelIdentifier) -> Decimal {
        let key = model.version ?? model.name.lowercased()
        guard let price = prices[key] else { return 0 }
        let inputCost = Decimal(inputTokens) * price.input / 1_000_000
        let outputCost = Decimal(outputTokens) * price.output / 1_000_000
        return inputCost + outputCost
    }
}
