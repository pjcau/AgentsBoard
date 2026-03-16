// MARK: - Server Composition Root
// Headless DI container — no UI, no AppKit. Wires Core protocols for server use.

import Foundation
import AgentsBoardCore

final class ServerCompositionRoot {

    // MARK: - Core Services

    let fleetManager: any FleetManaging
    let costAggregator: any CostAggregating
    let activityLogger: ActivityLogger
    let themeEngine: ThemeEngine
    let configProvider: any ConfigProviding

    // MARK: - Init

    init() {
        // Infrastructure
        let persistence = ServerPersistenceStub()

        // Config
        let config = ServerConfigStub()
        self.configProvider = config

        // Theme
        self.themeEngine = ThemeEngine()

        // Domain
        let notifications = NoOpNotificationManager()
        self.fleetManager = FleetManager(notificationManager: notifications)
        self.costAggregator = ServerCostAggregatorStub(persistence: persistence)
        self.activityLogger = ActivityLogger(persistence: persistence)
    }
}

// MARK: - Server-specific stubs (headless, no macOS frameworks)

private final class ServerPersistenceStub: PersistenceProviding {
    func save<T: Codable & Identifiable>(_ record: T, in table: String) throws {}
    func fetch<T: Codable & Identifiable>(from table: String, id: String) throws -> T? { nil }
    func fetchAll<T: Codable & Identifiable>(from table: String) throws -> [T] { [] }
    func delete(from table: String, id: String) throws {}
    func deleteAll(from table: String) throws {}
    func query<T: Codable>(sql: String, arguments: [Any]) throws -> [T] { [] }
}

private final class ServerConfigStub: ConfigProviding {
    var current: AppConfig = .default
    var onConfigChange: ((AppConfig) -> Void)?
    func reload() throws {}
}

private final class ServerCostAggregatorStub: CostAggregating {
    var onCostUpdate: (() -> Void)?
    init(persistence: any PersistenceProviding) {}
    func record(_ entry: CostEntry) {}
    func totalCost(forSession sessionId: String) -> Decimal { 0 }
    func totalCost(forProject projectId: String) -> Decimal { 0 }
    func fleetTotalCost() -> Decimal { 0 }
    func costHistory(from: Date, to: Date) -> [CostEntry] { [] }
    func dailyCost(forDate date: Date) -> Decimal { 0 }
}
