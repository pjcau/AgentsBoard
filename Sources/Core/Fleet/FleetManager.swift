// MARK: - Fleet Manager (Step 4.1)
// Aggregates all agent sessions cross-project with priority sorting.

import Foundation
import Observation

@Observable
public final class FleetManager: FleetManaging {

    // MARK: - Properties

    public private(set) var sessions: [any AgentSessionRepresentable] = []
    public private(set) var stats: FleetStats = .empty

    public var onFleetChange: (() -> Void)?

    private let sorter = FleetSorter()

    public init() {}

    // MARK: - FleetManaging

    public func register(_ session: any AgentSessionRepresentable) {
        sessions.append(session)
        sessions = sorter.sorted(sessions)
        recalculateStats()
        onFleetChange?()
    }

    public func unregister(sessionId: String) {
        sessions.removeAll { $0.sessionId == sessionId }
        recalculateStats()
        onFleetChange?()
    }

    public func session(byId id: String) -> (any AgentSessionRepresentable)? {
        sessions.first { $0.sessionId == id }
    }

    // MARK: - Refresh

    public func refresh() {
        sessions = sorter.sorted(sessions)
        recalculateStats()
        onFleetChange?()
    }

    // MARK: - Private

    private func recalculateStats() {
        var costByProvider: [AgentProvider: Decimal] = [:]
        var sessionsByState: [AgentState: Int] = [:]
        var totalCost: Decimal = 0
        var activeCount = 0
        var needsInputCount = 0
        var errorCount = 0

        for session in sessions {
            let state = session.state
            sessionsByState[state, default: 0] += 1
            totalCost += session.totalCost

            if let provider = session.agentInfo?.provider {
                costByProvider[provider, default: 0] += session.totalCost
            }

            switch state {
            case .working: activeCount += 1
            case .needsInput: needsInputCount += 1
            case .error: errorCount += 1
            case .inactive: break
            }
        }

        stats = FleetStats(
            totalSessions: sessions.count,
            activeSessions: activeCount,
            needsInputCount: needsInputCount,
            errorCount: errorCount,
            totalCost: totalCost,
            costByProvider: costByProvider,
            sessionsByState: sessionsByState
        )
    }
}

// MARK: - Fleet Sorter (SRP: sorting logic separate from fleet management)

final class FleetSorter {

    func sorted(_ sessions: [any AgentSessionRepresentable]) -> [any AgentSessionRepresentable] {
        sessions.sorted { a, b in
            let priorityA = priority(for: a.state)
            let priorityB = priority(for: b.state)

            if priorityA != priorityB {
                return priorityA < priorityB
            }

            // Within same priority, sort by most recent event
            let timeA = a.lastEventTime ?? a.startTime
            let timeB = b.lastEventTime ?? b.startTime
            return timeA > timeB
        }
    }

    private func priority(for state: AgentState) -> Int {
        switch state {
        case .needsInput: return 0  // Most urgent
        case .error: return 1
        case .working: return 2
        case .inactive: return 3
        }
    }
}

// MARK: - Fleet Filter (SRP: filtering logic separate)

struct FleetFilter {
    var providers: Set<AgentProvider>?
    var states: Set<AgentState>?
    var projectId: String?
    var modelName: String?
    var minCost: Decimal?
    var maxCost: Decimal?

    func apply(to sessions: [any AgentSessionRepresentable]) -> [any AgentSessionRepresentable] {
        sessions.filter { session in
            if let providers, let info = session.agentInfo, !providers.contains(info.provider) { return false }
            if let states, !states.contains(session.state) { return false }
            if let projectId, session.projectPath != projectId { return false }
            if let modelName, session.agentInfo?.model.name != modelName { return false }
            if let minCost, session.totalCost < minCost { return false }
            if let maxCost, session.totalCost > maxCost { return false }
            return true
        }
    }
}
