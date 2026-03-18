// MARK: - FFI Adapter types
// Headless implementations of Core protocols for use in the FFI layer.
// These mirror the App/CompositionRoot stubs but without any UI dependencies.

import Foundation
import AgentsBoardCore

// MARK: - Session Adapter (headless, no SwiftTerm UI)

@Observable
final class AgentSessionFFIAdapter: SessionEditable {
    let sessionId: String
    var agentInfo: AgentInfo?
    var state: AgentState = .working
    var totalCost: Decimal = 0
    var projectPath: String?
    let startTime: Date
    var lastEventTime: Date?
    var outputText: String = ""
    var launchCommand: String?
    var sessionName: String
    var gitBranch: String?
    var isArchived: Bool = false

    init(terminal: TerminalSession, name: String, projectPath: String?, command: String?) {
        self.sessionId = terminal.sessionId
        self.sessionName = name.isEmpty ? "Session" : name
        self.projectPath = projectPath
        self.launchCommand = command
        self.startTime = Date()
        self.lastEventTime = Date()
    }

    func sendInput(_ text: String) {
        // PTY input handled at terminal level
    }
}

// MARK: - Headless Notification Manager (no UI, no UserNotifications)

final class NotificationManagerFFI: NotificationManaging {
    func notifyNeedsInput(sessionId: String, sessionName: String) {}
    func notifyError(sessionId: String, sessionName: String, error: String) {}
    func notifyCostThreshold(sessionId: String, cost: Decimal, threshold: Decimal) {}
    func notifySessionCompleted(sessionId: String, sessionName: String) {}
}

// MARK: - Headless Persistence (in-memory stub)

final class PersistenceFFI: PersistenceProviding {
    func save<T: Codable & Identifiable>(_ record: T, in table: String) throws {}
    func fetch<T: Codable & Identifiable>(from table: String, id: String) throws -> T? { nil }
    func fetchAll<T: Codable & Identifiable>(from table: String) throws -> [T] { [] }
    func delete(from table: String, id: String) throws {}
    func deleteAll(from table: String) throws {}
    func query<T: Codable>(sql: String, arguments: [Any]) throws -> [T] { [] }
}

// MARK: - Headless Cost Aggregator

final class CostAggregatorFFI: CostAggregating {
    var onCostUpdate: (() -> Void)?
    private var entries: [CostEntry] = []

    init(persistence: any PersistenceProviding) {}

    func record(_ entry: CostEntry) {
        entries.append(entry)
        onCostUpdate?()
    }

    func totalCost(forSession sessionId: String) -> Decimal {
        entries.filter { $0.sessionId == sessionId }.reduce(0) { $0 + $1.cost }
    }

    func totalCost(forProject projectId: String) -> Decimal { 0 }

    func fleetTotalCost() -> Decimal {
        entries.reduce(0) { $0 + $1.cost }
    }

    func costHistory(from: Date, to: Date) -> [CostEntry] {
        entries.filter { $0.timestamp >= from && $0.timestamp <= to }
    }

    func dailyCost(forDate date: Date) -> Decimal { 0 }
}

// MARK: - Headless Config Manager

final class ConfigManagerFFI: ConfigProviding {
    var current: AppConfig = .default
    var onConfigChange: ((AppConfig) -> Void)?
    var cachedThemeName: [CChar] = Array("dark".utf8CString)

    func reload() throws {}

    func loadFromPath(_ path: String) -> Bool {
        // TODO: Implement YAML loading in future sprint
        return true
    }
}
