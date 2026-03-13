// MARK: - Composition Root (DIP: wires protocols → concrete types)
// This is the ONLY place where concrete implementations are instantiated.
// Everything else in the app depends on protocols only.

import Foundation
import AgentsBoardCore
import AgentsBoardUI
import Observation

@Observable
final class CompositionRoot {

    // MARK: - Core Services (exposed as protocols)

    private(set) var configProvider: any ConfigProviding
    private(set) var themeProvider: any ThemeProviding
    private(set) var persistence: any PersistenceProviding
    private(set) var fleetManager: any FleetManaging
    private(set) var costAggregator: any CostAggregating
    private(set) var projectManager: any ProjectManaging
    private(set) var hookEventParser: any HookEventParsing
    private(set) var recorder: any SessionRecordable

    // MARK: - Initialization

    init() {
        // Phase 1: Infrastructure (no dependencies)
        let yamlParser = YAMLParserImpl()
        let persistence = PersistenceStub()
        self.persistence = persistence

        // Phase 2: Configuration (depends on YAML parser)
        let configProvider = ConfigManagerStub(yamlParser: yamlParser)
        self.configProvider = configProvider

        let themeProvider = ThemeProviderStub()
        self.themeProvider = themeProvider

        // Phase 3: Domain services (depend on persistence + config)
        let costAggregator = CostAggregatorStub(persistence: persistence)
        self.costAggregator = costAggregator

        let projectManager = ProjectManagerStub(persistence: persistence)
        self.projectManager = projectManager

        let fleetManager = FleetManagerStub()
        self.fleetManager = fleetManager

        self.hookEventParser = HookEventParserStub()
        self.recorder = RecorderStub()
    }
}

// MARK: - Stub implementations (replaced incrementally in later sprints)

// These exist so the app compiles and launches with a window.
// Each sprint replaces stubs with real implementations.

private final class YAMLParserImpl: YAMLParsing {
    func decode<T: Decodable>(_ type: T.Type, from yaml: String) throws -> T {
        fatalError("YAMLParser: implement in Step 1.3")
    }
    func encode<T: Encodable>(_ value: T) throws -> String {
        fatalError("YAMLParser: implement in Step 1.3")
    }
}

private final class PersistenceStub: PersistenceProviding {
    func save<T: Codable & Identifiable>(_ record: T, in table: String) throws {}
    func fetch<T: Codable & Identifiable>(from table: String, id: String) throws -> T? { nil }
    func fetchAll<T: Codable & Identifiable>(from table: String) throws -> [T] { [] }
    func delete(from table: String, id: String) throws {}
    func deleteAll(from table: String) throws {}
    func query<T: Codable>(sql: String, arguments: [Any]) throws -> [T] { [] }
}

private final class ConfigManagerStub: ConfigProviding {
    var current: AppConfig = .default
    var onConfigChange: ((AppConfig) -> Void)?
    init(yamlParser: any YAMLParsing) {}
    func reload() throws {}
}

private final class ThemeProviderStub: ThemeProviding {
    var currentTheme: Theme = Theme(
        name: "dark",
        ansiColors: Array(repeating: "#000000", count: 16),
        foreground: "#FFFFFF",
        background: "#1E1E1E",
        accentColor: "#007AFF",
        sidebarBackground: "#252525",
        cardBackground: "#2D2D2D",
        borderColor: "#3D3D3D",
        textPrimary: "#FFFFFF",
        textSecondary: "#8E8E93"
    )
    var availableThemes: [String] = ["dark"]
    var onThemeChange: ((Theme) -> Void)?
    func loadTheme(named name: String) throws {}
}

private final class CostAggregatorStub: CostAggregating {
    var onCostUpdate: (() -> Void)?
    init(persistence: any PersistenceProviding) {}
    func record(_ entry: CostEntry) {}
    func totalCost(forSession sessionId: String) -> Decimal { 0 }
    func totalCost(forProject projectId: String) -> Decimal { 0 }
    func fleetTotalCost() -> Decimal { 0 }
    func costHistory(from: Date, to: Date) -> [CostEntry] { [] }
    func dailyCost(forDate date: Date) -> Decimal { 0 }
}

private final class ProjectManagerStub: ProjectManaging {
    var projects: [ProjectInfo] = []
    var onProjectsChange: (() -> Void)?
    init(persistence: any PersistenceProviding) {}
    func discover(in directory: String) throws -> [ProjectInfo] { [] }
    func add(_ project: ProjectInfo) throws {}
    func remove(projectId: String) throws {}
    func project(byId id: String) -> ProjectInfo? { nil }
    func project(byPath path: String) -> ProjectInfo? { nil }
}

private final class FleetManagerStub: FleetManaging {
    var sessions: [any AgentSessionRepresentable] = []
    var stats: FleetStats = .empty
    var onFleetChange: (() -> Void)?
    func register(_ session: any AgentSessionRepresentable) {}
    func unregister(sessionId: String) {}
    func session(byId id: String) -> (any AgentSessionRepresentable)? { nil }
}

private final class HookEventParserStub: HookEventParsing {
    func parse(json: Data) throws -> HookEvent {
        fatalError("HookEventParser: implement in Step 3.3")
    }
}

private final class RecorderStub: SessionRecordable {
    var isRecording: Bool = false
    func startRecording(sessionId: String) throws {}
    func stopRecording(sessionId: String) throws -> URL { URL(fileURLWithPath: "/dev/null") }
    func recordData(_ data: Data, forSession sessionId: String) {}
}
