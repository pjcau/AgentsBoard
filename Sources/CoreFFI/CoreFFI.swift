// MARK: - CoreFFI — @_cdecl exports for C/C++ consumption
// This module wraps AgentsBoardCore behind a stable C ABI.
// All functions are exported as C symbols via @_cdecl.
// Opaque handles use Unmanaged<T> to bridge Swift objects to C pointers.

import Foundation
import AgentsBoardCore

// MARK: - Version

@_cdecl("ab_version")
public func ab_version() -> UnsafePointer<CChar> {
    let version: StaticString = "0.9.0"
    return UnsafeRawPointer(version.utf8Start).assumingMemoryBound(to: CChar.self)
}

// MARK: - Core Lifecycle

/// Internal wrapper that owns all Core services (mirrors CompositionRoot but headless).
final class ABCoreHandle {
    let fleetManager: FleetManager
    let costAggregator: CostAggregatorFFI
    let configManager: ConfigManagerFFI
    let activityLogger: ActivityLogger
    let persistence: PersistenceFFI
    let notificationManager: NotificationManagerFFI

    var fleetCallback: ABFleetCallback?
    var fleetCallbackContext: UnsafeMutableRawPointer?

    // Keep session handles alive
    var sessionHandles: [String: ABSessionHandle] = [:]

    init() {
        let persistence = PersistenceFFI()
        self.persistence = persistence
        self.notificationManager = NotificationManagerFFI()
        self.fleetManager = FleetManager(notificationManager: notificationManager)
        self.costAggregator = CostAggregatorFFI(persistence: persistence)
        self.configManager = ConfigManagerFFI()
        self.activityLogger = ActivityLogger(persistence: persistence)

        // Wire fleet change callback
        fleetManager.onFleetChange = { [weak self] in
            guard let self, let cb = self.fleetCallback else { return }
            cb(ABFleetEventType.statsChanged.rawValue, self.fleetCallbackContext)
        }
    }
}

@_cdecl("ab_core_create")
public func ab_core_create() -> UnsafeMutableRawPointer? {
    let core = ABCoreHandle()
    let unmanaged = Unmanaged.passRetained(core)
    return unmanaged.toOpaque()
}

@_cdecl("ab_core_destroy")
public func ab_core_destroy(_ ptr: UnsafeMutableRawPointer?) {
    guard let ptr else { return }
    Unmanaged<ABCoreHandle>.fromOpaque(ptr).release()
}

// MARK: - Helpers

private func coreHandle(_ ptr: UnsafeMutableRawPointer) -> ABCoreHandle {
    Unmanaged<ABCoreHandle>.fromOpaque(ptr).takeUnretainedValue()
}

// MARK: - Fleet Operations

@_cdecl("ab_fleet_get_stats")
public func ab_fleet_get_stats(
    _ ptr: UnsafeMutableRawPointer?,
    _ outStats: UnsafeMutablePointer<Int32>?,  // [total, active, needsInput, error]
    _ outCost: UnsafeMutablePointer<Double>?
) {
    guard let ptr, let outStats, let outCost else { return }
    let core = coreHandle(ptr)
    let stats = core.fleetManager.stats
    outStats[0] = Int32(stats.totalSessions)
    outStats[1] = Int32(stats.activeSessions)
    outStats[2] = Int32(stats.needsInputCount)
    outStats[3] = Int32(stats.errorCount)
    outCost.pointee = NSDecimalNumber(decimal: stats.totalCost).doubleValue
}

@_cdecl("ab_fleet_session_count")
public func ab_fleet_session_count(_ ptr: UnsafeMutableRawPointer?) -> Int32 {
    guard let ptr else { return 0 }
    return Int32(coreHandle(ptr).fleetManager.sessions.count)
}

/// Get a session handle by fleet index. Returns NULL if out of range.
/// The returned handle is borrowed — do NOT call ab_session_destroy on it.
@_cdecl("ab_fleet_get_session")
public func ab_fleet_get_session(
    _ ptr: UnsafeMutableRawPointer?,
    _ index: Int32
) -> UnsafeMutableRawPointer? {
    guard let ptr else { return nil }
    let core = coreHandle(ptr)
    let sessions = core.fleetManager.sessions
    guard index >= 0, Int(index) < sessions.count else { return nil }
    let session = sessions[Int(index)]

    // Return existing handle or create one
    if let handle = core.sessionHandles[session.sessionId] {
        return Unmanaged.passUnretained(handle).toOpaque()
    }
    let handle = ABSessionHandle(session)
    core.sessionHandles[session.sessionId] = handle
    return Unmanaged.passUnretained(handle).toOpaque()
}

/// Get a session handle by ID. Returns NULL if not found.
@_cdecl("ab_fleet_get_session_by_id")
public func ab_fleet_get_session_by_id(
    _ ptr: UnsafeMutableRawPointer?,
    _ sessionId: UnsafePointer<CChar>?
) -> UnsafeMutableRawPointer? {
    guard let ptr, let sessionId else { return nil }
    let core = coreHandle(ptr)
    let id = String(cString: sessionId)
    guard let session = core.fleetManager.session(byId: id) else { return nil }

    if let handle = core.sessionHandles[id] {
        return Unmanaged.passUnretained(handle).toOpaque()
    }
    let handle = ABSessionHandle(session)
    core.sessionHandles[id] = handle
    return Unmanaged.passUnretained(handle).toOpaque()
}

@_cdecl("ab_fleet_set_callback")
public func ab_fleet_set_callback(
    _ ptr: UnsafeMutableRawPointer?,
    _ callback: ABFleetCallback?,
    _ context: UnsafeMutableRawPointer?
) {
    guard let ptr else { return }
    let core = coreHandle(ptr)
    core.fleetCallback = callback
    core.fleetCallbackContext = context
}

// MARK: - Session Operations

/// Internal session handle wrapping an AgentSessionRepresentable.
final class ABSessionHandle {
    let session: any AgentSessionRepresentable
    var callback: ABSessionCallback?
    var callbackContext: UnsafeMutableRawPointer?

    // Cached C strings (kept alive as long as handle exists)
    var cachedId: [CChar]
    var cachedName: [CChar]
    var cachedProjectPath: [CChar]?
    var cachedCommand: [CChar]?
    var cachedBranch: [CChar]?
    var cachedOutput: [CChar]

    init(_ session: any AgentSessionRepresentable) {
        self.session = session
        self.cachedId = Array(session.sessionId.utf8CString)
        self.cachedName = Array(session.sessionName.utf8CString)
        self.cachedProjectPath = session.projectPath.map { Array($0.utf8CString) }
        self.cachedCommand = session.launchCommand.map { Array($0.utf8CString) }
        self.cachedBranch = session.gitBranch.map { Array($0.utf8CString) }
        self.cachedOutput = Array(session.outputText.utf8CString)
    }

    func refreshCache() {
        cachedName = Array(session.sessionName.utf8CString)
        cachedProjectPath = session.projectPath.map { Array($0.utf8CString) }
        cachedCommand = session.launchCommand.map { Array($0.utf8CString) }
        cachedBranch = session.gitBranch.map { Array($0.utf8CString) }
        cachedOutput = Array(session.outputText.utf8CString)
    }
}

@_cdecl("ab_session_create")
public func ab_session_create(
    _ ptr: UnsafeMutableRawPointer?,
    _ command: UnsafePointer<CChar>?,
    _ name: UnsafePointer<CChar>?,
    _ workdir: UnsafePointer<CChar>?
) -> UnsafeMutableRawPointer? {
    guard let ptr, let command, let name else { return nil }
    let core = coreHandle(ptr)

    let cmdStr = String(cString: command)
    let nameStr = String(cString: name)
    let wdStr = workdir.map { String(cString: $0) }

    let terminal = TerminalSession()
    let adapter = AgentSessionFFIAdapter(
        terminal: terminal,
        name: nameStr,
        projectPath: wdStr,
        command: cmdStr.isEmpty ? nil : cmdStr
    )

    core.fleetManager.register(adapter)

    let handle = ABSessionHandle(adapter)
    core.sessionHandles[adapter.sessionId] = handle

    core.activityLogger.log(ActivityEvent(
        sessionId: adapter.sessionId,
        eventType: .stateChange,
        details: "Session launched via FFI: \(nameStr)"
    ))

    return Unmanaged.passRetained(handle).toOpaque()
}

@_cdecl("ab_session_send_input")
public func ab_session_send_input(
    _ ptr: UnsafeMutableRawPointer?,
    _ input: UnsafePointer<CChar>?,
    _ len: Int32
) {
    guard let ptr, let input else { return }
    let handle = Unmanaged<ABSessionHandle>.fromOpaque(ptr).takeUnretainedValue()
    let text = String(cString: input)
    handle.session.sendInput(text)
}

@_cdecl("ab_session_get_state")
public func ab_session_get_state(_ ptr: UnsafeMutableRawPointer?) -> Int32 {
    guard let ptr else { return ABAgentState.inactive.rawValue }
    let handle = Unmanaged<ABSessionHandle>.fromOpaque(ptr).takeUnretainedValue()
    return handle.session.state.toCState().rawValue
}

@_cdecl("ab_session_get_id")
public func ab_session_get_id(_ ptr: UnsafeMutableRawPointer?) -> UnsafePointer<CChar>? {
    guard let ptr else { return nil }
    let handle = Unmanaged<ABSessionHandle>.fromOpaque(ptr).takeUnretainedValue()
    return handle.cachedId.withUnsafeBufferPointer { $0.baseAddress }
}

@_cdecl("ab_session_get_name")
public func ab_session_get_name(_ ptr: UnsafeMutableRawPointer?) -> UnsafePointer<CChar>? {
    guard let ptr else { return nil }
    let handle = Unmanaged<ABSessionHandle>.fromOpaque(ptr).takeUnretainedValue()
    handle.refreshCache()
    return handle.cachedName.withUnsafeBufferPointer { $0.baseAddress }
}

@_cdecl("ab_session_get_cost")
public func ab_session_get_cost(_ ptr: UnsafeMutableRawPointer?) -> Double {
    guard let ptr else { return 0 }
    let handle = Unmanaged<ABSessionHandle>.fromOpaque(ptr).takeUnretainedValue()
    return NSDecimalNumber(decimal: handle.session.totalCost).doubleValue
}

@_cdecl("ab_session_get_output")
public func ab_session_get_output(_ ptr: UnsafeMutableRawPointer?) -> UnsafePointer<CChar>? {
    guard let ptr else { return nil }
    let handle = Unmanaged<ABSessionHandle>.fromOpaque(ptr).takeUnretainedValue()
    handle.refreshCache()
    return handle.cachedOutput.withUnsafeBufferPointer { $0.baseAddress }
}

@_cdecl("ab_session_get_output_length")
public func ab_session_get_output_length(_ ptr: UnsafeMutableRawPointer?) -> Int32 {
    guard let ptr else { return 0 }
    let handle = Unmanaged<ABSessionHandle>.fromOpaque(ptr).takeUnretainedValue()
    return Int32(handle.session.outputText.utf8.count)
}

@_cdecl("ab_session_set_callback")
public func ab_session_set_callback(
    _ ptr: UnsafeMutableRawPointer?,
    _ callback: ABSessionCallback?,
    _ context: UnsafeMutableRawPointer?
) {
    guard let ptr else { return }
    let handle = Unmanaged<ABSessionHandle>.fromOpaque(ptr).takeUnretainedValue()
    handle.callback = callback
    handle.callbackContext = context
}

@_cdecl("ab_session_archive")
public func ab_session_archive(_ ptr: UnsafeMutableRawPointer?, _ sessionId: UnsafePointer<CChar>?) {
    guard let ptr, let sessionId else { return }
    coreHandle(ptr).fleetManager.archiveSession(id: String(cString: sessionId))
}

@_cdecl("ab_session_unarchive")
public func ab_session_unarchive(_ ptr: UnsafeMutableRawPointer?, _ sessionId: UnsafePointer<CChar>?) {
    guard let ptr, let sessionId else { return }
    coreHandle(ptr).fleetManager.unarchiveSession(id: String(cString: sessionId))
}

@_cdecl("ab_session_delete")
public func ab_session_delete(_ ptr: UnsafeMutableRawPointer?, _ sessionId: UnsafePointer<CChar>?) {
    guard let ptr, let sessionId else { return }
    let id = String(cString: sessionId)
    let core = coreHandle(ptr)
    core.fleetManager.deleteSession(id: id)
    core.sessionHandles.removeValue(forKey: id)
}

@_cdecl("ab_session_destroy")
public func ab_session_destroy(_ ptr: UnsafeMutableRawPointer?) {
    guard let ptr else { return }
    Unmanaged<ABSessionHandle>.fromOpaque(ptr).release()
}

// MARK: - Configuration

@_cdecl("ab_config_load")
public func ab_config_load(_ ptr: UnsafeMutableRawPointer?, _ path: UnsafePointer<CChar>?) -> Bool {
    guard let ptr, let path else { return false }
    let core = coreHandle(ptr)
    let pathStr = String(cString: path)
    return core.configManager.loadFromPath(pathStr)
}

@_cdecl("ab_config_get_theme")
public func ab_config_get_theme(_ ptr: UnsafeMutableRawPointer?) -> UnsafePointer<CChar>? {
    guard let ptr else { return nil }
    let core = coreHandle(ptr)
    return core.configManager.cachedThemeName.withUnsafeBufferPointer { $0.baseAddress }
}

@_cdecl("ab_config_get_layout")
public func ab_config_get_layout(_ ptr: UnsafeMutableRawPointer?) -> Int32 {
    guard let ptr else { return ABLayoutMode.fleet.rawValue }
    return coreHandle(ptr).configManager.current.layout.toCLayout().rawValue
}

@_cdecl("ab_config_set_layout")
public func ab_config_set_layout(_ ptr: UnsafeMutableRawPointer?, _ mode: Int32) {
    guard let ptr else { return }
    coreHandle(ptr).configManager.current.layout = ABLayoutMode(rawValue: mode).toSwiftLayout()
}

@_cdecl("ab_config_get_font_size")
public func ab_config_get_font_size(_ ptr: UnsafeMutableRawPointer?) -> Double {
    guard let ptr else { return 13.0 }
    return coreHandle(ptr).configManager.current.fontSize
}

@_cdecl("ab_config_set_font_size")
public func ab_config_set_font_size(_ ptr: UnsafeMutableRawPointer?, _ size: Double) {
    guard let ptr else { return }
    coreHandle(ptr).configManager.current.fontSize = size
}

// MARK: - Cost Tracking

@_cdecl("ab_cost_get_fleet_total")
public func ab_cost_get_fleet_total(_ ptr: UnsafeMutableRawPointer?) -> Double {
    guard let ptr else { return 0 }
    return NSDecimalNumber(decimal: coreHandle(ptr).costAggregator.fleetTotalCost()).doubleValue
}

@_cdecl("ab_cost_get_session_total")
public func ab_cost_get_session_total(_ ptr: UnsafeMutableRawPointer?, _ sessionId: UnsafePointer<CChar>?) -> Double {
    guard let ptr, let sessionId else { return 0 }
    let id = String(cString: sessionId)
    return NSDecimalNumber(decimal: coreHandle(ptr).costAggregator.totalCost(forSession: id)).doubleValue
}

@_cdecl("ab_cost_get_burn_rate")
public func ab_cost_get_burn_rate(_ ptr: UnsafeMutableRawPointer?) -> Double {
    guard let ptr else { return 0 }
    // Burn rate not directly available on CostAggregating protocol — return 0 for now
    return 0
}

// MARK: - Additional Session Getters

@_cdecl("ab_session_get_provider")
public func ab_session_get_provider(_ ptr: UnsafeMutableRawPointer?) -> Int32 {
    guard let ptr else { return ABProvider.custom.rawValue }
    let handle = Unmanaged<ABSessionHandle>.fromOpaque(ptr).takeUnretainedValue()
    return (handle.session.agentInfo?.provider.toCProvider() ?? .custom).rawValue
}

@_cdecl("ab_session_get_project_path")
public func ab_session_get_project_path(_ ptr: UnsafeMutableRawPointer?) -> UnsafePointer<CChar>? {
    guard let ptr else { return nil }
    let handle = Unmanaged<ABSessionHandle>.fromOpaque(ptr).takeUnretainedValue()
    handle.refreshCache()
    guard let cached = handle.cachedProjectPath else { return nil }
    return cached.withUnsafeBufferPointer { $0.baseAddress }
}

@_cdecl("ab_session_get_start_time")
public func ab_session_get_start_time(_ ptr: UnsafeMutableRawPointer?) -> Double {
    guard let ptr else { return 0 }
    let handle = Unmanaged<ABSessionHandle>.fromOpaque(ptr).takeUnretainedValue()
    return handle.session.startTime.timeIntervalSince1970
}

// MARK: - Enum Conversions

extension AgentState {
    func toCState() -> ABAgentState {
        switch self {
        case .working: return .working
        case .needsInput: return .needsInput
        case .error: return .error
        case .inactive: return .inactive
        }
    }
}

extension AgentProvider {
    func toCProvider() -> ABProvider {
        switch self {
        case .claude: return .claude
        case .codex: return .codex
        case .aider: return .aider
        case .gemini: return .gemini
        case .custom: return .custom
        }
    }
}

extension LayoutMode {
    func toCLayout() -> ABLayoutMode {
        switch self {
        case .single: return .single
        case .list: return .list
        case .twoColumn: return .twoColumn
        case .threeColumn: return .threeColumn
        case .fleet: return .fleet
        }
    }
}

extension ABLayoutMode {
    func toSwiftLayout() -> LayoutMode {
        switch self {
        case .single: return .single
        case .list: return .list
        case .twoColumn: return .twoColumn
        case .threeColumn: return .threeColumn
        case .fleet: return .fleet
        default: return .fleet
        }
    }
}
