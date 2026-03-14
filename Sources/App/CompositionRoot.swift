// MARK: - Composition Root (DIP: wires protocols → concrete types)
// This is the ONLY place where concrete implementations are instantiated.
// Everything else in the app depends on protocols only.

import Foundation
import AppKit
import AgentsBoardCore
import AgentsBoardUI
import Observation

@Observable
final class CompositionRoot {

    // MARK: - Core Services (exposed as protocols)

    private(set) var configProvider: any ConfigProviding
    private(set) var themeProvider: any ThemeProviding
    private(set) var persistence: any PersistenceProviding
    private(set) var notificationManager: any NotificationManaging
    private(set) var fleetManager: any FleetManaging
    private(set) var costAggregator: any CostAggregating
    private(set) var projectManager: any ProjectManaging
    private(set) var hookEventParser: any HookEventParsing
    private(set) var recorder: any SessionRecordable

    // MARK: - Orchestration

    private(set) var taskRouter: TaskRouter
    private(set) var sessionRemixer: SessionRemixer

    // MARK: - UI Services

    private(set) var commandRegistry: CommandRegistry
    private(set) var activityLogger: ActivityLogger
    private(set) var layoutEngine: LayoutEngine
    private(set) var statusBarController: StatusBarController?
    private(set) var menuBarViewModel: MenuBarViewModel?

    // MARK: - Navigation State

    let navigationState = NavigationState()

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

        let notificationManager = NotificationManager()
        self.notificationManager = notificationManager

        let fleetManager = FleetManager(notificationManager: notificationManager)
        self.fleetManager = fleetManager

        self.hookEventParser = HookEventParserStub()
        self.recorder = RecorderStub()

        // Phase 3b: Orchestration
        self.taskRouter = TaskRouter()
        self.sessionRemixer = SessionRemixer()

        // Phase 4: UI services
        let commandRegistry = CommandRegistry()
        self.commandRegistry = commandRegistry

        self.activityLogger = ActivityLogger(persistence: persistence)
        self.layoutEngine = LayoutEngine()

        // Phase 4b: Status bar widget
        let menuBarVM = MenuBarViewModel(fleetManager: fleetManager)
        self.menuBarViewModel = menuBarVM
        let statusBar = StatusBarController(viewModel: menuBarVM)
        self.statusBarController = statusBar

        // Phase 5: Register default commands
        registerDefaultCommands()

        // Phase 6: Setup status bar (after init completes)
        DispatchQueue.main.async {
            statusBar.setup()
            menuBarVM.onNewSession = { [weak self] in
                self?.navigationState.showingLauncher = true
            }
            menuBarVM.onOpenMainWindow = {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    // MARK: - Session Launch

    func launchSession(command: String, name: String, workdir: String?) {
        print("[LaunchSession] Creating session: \(name) cmd=\(command) workdir=\(workdir ?? "nil")")

        let session = TerminalSession()
        // Store nil for empty commands — prevents TerminalEmulatorView from spawning a PTY
        let effectiveCommand = command.trimmingCharacters(in: .whitespaces).isEmpty ? nil : command
        let agentSession = AgentSessionAdapter(
            terminal: session,
            name: name.isEmpty ? "Session" : name,
            projectPath: workdir,
            command: effectiveCommand
        )
        // Placeholder sessions (no command) start as inactive
        if effectiveCommand == nil {
            agentSession.state = .inactive
        }

        print("[LaunchSession] Registering session \(agentSession.sessionId) in fleet")
        fleetManager.register(agentSession)
        navigationState.selectedSessionId = agentSession.sessionId

        activityLogger.log(ActivityEvent(
            sessionId: agentSession.sessionId,
            eventType: .stateChange,
            details: "Session launched: \(name) — \(command)"
        ))
        print("[LaunchSession] Done. Fleet now has \(fleetManager.sessions.count) sessions")
    }

    // MARK: - Session Remix

    func remixSession(config: UIRemixConfig, sourceSession: any AgentSessionRepresentable) {
        let coreConfig = SessionRemixer.RemixConfig(
            sourceSession: sourceSession,
            targetProvider: config.targetProvider,
            branchName: config.branchName,
            contextDepth: config.contextDepth,
            projectPath: config.projectPath
        )

        Task {
            do {
                let result = try await sessionRemixer.remix(config: coreConfig)
                await MainActor.run {
                    // Launch a new session in the worktree
                    launchSession(
                        command: result.targetProvider.defaultCommand,
                        name: "Remix: \(result.branchName)",
                        workdir: result.worktreePath
                    )

                    activityLogger.log(ActivityEvent(
                        sessionId: sourceSession.sessionId,
                        eventType: .stateChange,
                        details: "Remixed to worktree: \(result.branchName)"
                    ))
                }
            } catch {
                await MainActor.run {
                    activityLogger.log(ActivityEvent(
                        sessionId: sourceSession.sessionId,
                        eventType: .error,
                        details: "Remix failed: \(error.localizedDescription)"
                    ))
                }
            }
        }
    }

    // MARK: - Default Commands

    private func registerDefaultCommands() {
        let nav = navigationState

        commandRegistry.register(command: PaletteCommand(
            id: "session.new", title: "New Session",
            subtitle: "Launch a new agent session",
            icon: "plus.circle", category: .session, shortcut: "⌘N",
            action: { nav.showingLauncher = true }
        ))

        commandRegistry.register(command: PaletteCommand(
            id: "nav.fleet", title: "Fleet Overview",
            subtitle: "View all agents at a glance",
            icon: "square.grid.2x2", category: .navigation, shortcut: "⇧⌘F",
            action: { nav.showingFleetOverview = true }
        ))

        commandRegistry.register(command: PaletteCommand(
            id: "nav.activity", title: "Activity Log",
            subtitle: "View recent events",
            icon: "list.bullet", category: .navigation, shortcut: "⌘L",
            action: { nav.showingActivityLog = true }
        ))

        commandRegistry.register(command: PaletteCommand(
            id: "nav.palette", title: "Command Palette",
            subtitle: "Search commands",
            icon: "magnifyingglass", category: .navigation, shortcut: "⌘K",
            action: { nav.showingCommandPalette.toggle() }
        ))

        for mode in LayoutMode.allCases {
            commandRegistry.register(command: PaletteCommand(
                id: "layout.\(mode)", title: "Layout: \(String(describing: mode).capitalized)",
                subtitle: nil,
                icon: "rectangle.split.3x1", category: .layout, shortcut: nil,
                action: { nav.layoutMode = mode }
            ))
        }
    }
}

// MARK: - Agent Session Adapter

/// Session placeholder for fleet registration.
/// The actual terminal process is managed by SwiftTerm's LocalProcessTerminalView in the UI.
@Observable
final class AgentSessionAdapter: SessionEditable {
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
        self.gitBranch = Self.detectBranch(at: projectPath)
    }

    func sendInput(_ text: String) {
        // Input is handled directly by SwiftTerm's TerminalView
    }

    private static func detectBranch(at path: String?) -> String? {
        guard let path, !path.isEmpty else { return nil }
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["rev-parse", "--abbrev-ref", "HEAD"]
        process.currentDirectoryURL = URL(fileURLWithPath: path)
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let branch = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (branch?.isEmpty ?? true) ? nil : branch
        } catch {
            return nil
        }
    }
}

// MARK: - Stub implementations (replaced incrementally in later sprints)

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
