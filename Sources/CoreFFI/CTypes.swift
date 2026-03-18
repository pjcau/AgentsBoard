// MARK: - C-compatible type definitions
// These mirror the types in include/agentsboard.h exactly.
// Swift @_cdecl functions use these types; Qt/C++ uses the C header.

import Foundation

// MARK: - Enums (backed by Int32 for C ABI stability)

public struct ABProvider: RawRepresentable, Equatable, Sendable {
    public let rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }

    public static let claude  = ABProvider(rawValue: 0)
    public static let codex   = ABProvider(rawValue: 1)
    public static let aider   = ABProvider(rawValue: 2)
    public static let gemini  = ABProvider(rawValue: 3)
    public static let custom  = ABProvider(rawValue: 4)
}

public struct ABAgentState: RawRepresentable, Equatable, Sendable {
    public let rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }

    public static let working    = ABAgentState(rawValue: 0)
    public static let needsInput = ABAgentState(rawValue: 1)
    public static let error      = ABAgentState(rawValue: 2)
    public static let inactive   = ABAgentState(rawValue: 3)
}

public struct ABLayoutMode: RawRepresentable, Equatable, Sendable {
    public let rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }

    public static let single      = ABLayoutMode(rawValue: 0)
    public static let list        = ABLayoutMode(rawValue: 1)
    public static let twoColumn   = ABLayoutMode(rawValue: 2)
    public static let threeColumn = ABLayoutMode(rawValue: 3)
    public static let fleet       = ABLayoutMode(rawValue: 4)
}

// MARK: - Data Structs

public struct ABFleetStats {
    public var total_sessions: Int32 = 0
    public var active_sessions: Int32 = 0
    public var needs_input_count: Int32 = 0
    public var error_count: Int32 = 0
    public var total_cost: Double = 0

    public init() {}

    public init(total_sessions: Int32, active_sessions: Int32,
                needs_input_count: Int32, error_count: Int32, total_cost: Double) {
        self.total_sessions = total_sessions
        self.active_sessions = active_sessions
        self.needs_input_count = needs_input_count
        self.error_count = error_count
        self.total_cost = total_cost
    }
}

public struct ABSessionInfo {
    public var session_id: UnsafePointer<CChar>?
    public var session_name: UnsafePointer<CChar>?
    public var project_path: UnsafePointer<CChar>?
    public var git_branch: UnsafePointer<CChar>?
    public var command: UnsafePointer<CChar>?
    public var state: ABAgentState = .inactive
    public var provider: ABProvider = .custom
    public var total_cost: Double = 0
    public var start_time: Double = 0

    public init() {}
}

// MARK: - Event Types

public struct ABFleetEventType: RawRepresentable, Equatable, Sendable {
    public let rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }

    public static let sessionAdded   = ABFleetEventType(rawValue: 0)
    public static let sessionRemoved = ABFleetEventType(rawValue: 1)
    public static let sessionUpdated = ABFleetEventType(rawValue: 2)
    public static let statsChanged   = ABFleetEventType(rawValue: 3)
}

public struct ABFleetEvent {
    public var type: ABFleetEventType = .statsChanged
    public var session_id: UnsafePointer<CChar>?

    public init() {}
}

public struct ABSessionEventType: RawRepresentable, Equatable, Sendable {
    public let rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }

    public static let stateChanged = ABSessionEventType(rawValue: 0)
    public static let output       = ABSessionEventType(rawValue: 1)
    public static let costUpdated  = ABSessionEventType(rawValue: 2)
}

public struct ABSessionEvent {
    public var type: ABSessionEventType = .stateChanged
    public var new_state: ABAgentState = .inactive
    public var output_chunk: UnsafePointer<CChar>?
    public var output_len: Int32 = 0
    public var cost_delta: Double = 0

    public init() {}
}

// MARK: - Callback typedefs
// Note: Swift structs with optional pointers aren't @convention(c) compatible.
// Callbacks pass raw event type + context; callers query details via API functions.

public typealias ABFleetCallback = @convention(c) (Int32, UnsafeMutableRawPointer?) -> Void
public typealias ABSessionCallback = @convention(c) (Int32, UnsafeMutableRawPointer?) -> Void
