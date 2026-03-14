// MARK: - Fleet Protocols

import Foundation

/// Aggregates agent sessions cross-project, sorts by priority, provides fleet stats.
public protocol FleetManaging: AnyObject {
    var sessions: [any AgentSessionRepresentable] { get }
    var stats: FleetStats { get }

    func register(_ session: any AgentSessionRepresentable)
    func unregister(sessionId: String)
    func session(byId id: String) -> (any AgentSessionRepresentable)?

    var onFleetChange: (() -> Void)? { get set }
}

/// Represents a single agent session within the fleet (read-only view).
public protocol AgentSessionRepresentable: AnyObject {
    var sessionId: String { get }
    var agentInfo: AgentInfo? { get }
    var state: AgentState { get }
    var totalCost: Decimal { get }
    var projectPath: String? { get }
    var startTime: Date { get }
    var lastEventTime: Date? { get }
    var outputText: String { get }
    var launchCommand: String? { get }
    var sessionName: String { get }
    var gitBranch: String? { get }
    func sendInput(_ text: String)
}

/// Sessions that support editing their metadata.
public protocol SessionEditable: AgentSessionRepresentable {
    var sessionName: String { get set }
    var projectPath: String? { get set }
    var gitBranch: String? { get set }
    var launchCommand: String? { get set }
}

extension AgentSessionRepresentable {
    public var outputText: String { "" }
    public var launchCommand: String? { nil }
    public var sessionName: String { "Session" }
    public var gitBranch: String? { nil }
    public func sendInput(_ text: String) {}
}

/// Aggregated statistics for the fleet.
public struct FleetStats: Sendable {
    public let totalSessions: Int
    public let activeSessions: Int
    public let needsInputCount: Int
    public let errorCount: Int
    public let totalCost: Decimal
    public let costByProvider: [AgentProvider: Decimal]
    public let sessionsByState: [AgentState: Int]

    public init(totalSessions: Int, activeSessions: Int, needsInputCount: Int, errorCount: Int, totalCost: Decimal, costByProvider: [AgentProvider: Decimal], sessionsByState: [AgentState: Int]) {
        self.totalSessions = totalSessions
        self.activeSessions = activeSessions
        self.needsInputCount = needsInputCount
        self.errorCount = errorCount
        self.totalCost = totalCost
        self.costByProvider = costByProvider
        self.sessionsByState = sessionsByState
    }

    public static let empty = FleetStats(
        totalSessions: 0,
        activeSessions: 0,
        needsInputCount: 0,
        errorCount: 0,
        totalCost: 0,
        costByProvider: [:],
        sessionsByState: [:]
    )
}
