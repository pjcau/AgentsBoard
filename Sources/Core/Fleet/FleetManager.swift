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
    private let notificationManager: any NotificationManaging

    /// Tracks each session's last-known state so we can fire notifications only
    /// on genuine transitions into noteworthy states.
    private var lastNotifiedStates: [String: AgentState] = [:]

    /// When non-nil, sessions are arranged in this explicit ID order instead of
    /// being sorted by priority.  Set by `reorder(sessionId:toIndex:)`.
    private var manualOrder: [String]?

    /// - Parameter notificationManager: Injected notification dispatcher.
    ///   Defaults to `NotificationManager()` in production; inject a mock in tests.
    public init(notificationManager: any NotificationManaging = NotificationManager()) {
        self.notificationManager = notificationManager
    }

    // MARK: - Computed

    public var activeSessions: [any AgentSessionRepresentable] {
        sessions.filter { !$0.isArchived }
    }

    // MARK: - FleetManaging

    public func register(_ session: any AgentSessionRepresentable) {
        sessions.append(session)
        sessions = applyOrder(to: sessions)
        recalculateStats()
        // Seed the initial state so the first refresh does not produce a
        // spurious notification for a session that was already needsInput
        // when it was registered.
        lastNotifiedStates[session.sessionId] = session.state
        onFleetChange?()
    }

    public func unregister(sessionId: String) {
        sessions.removeAll { $0.sessionId == sessionId }
        manualOrder?.removeAll { $0 == sessionId }
        lastNotifiedStates.removeValue(forKey: sessionId)
        recalculateStats()
        onFleetChange?()
    }

    public func session(byId id: String) -> (any AgentSessionRepresentable)? {
        sessions.first { $0.sessionId == id }
    }

    // MARK: - Reorder

    public func reorder(sessionId: String, toIndex: Int) {
        guard let fromIndex = sessions.firstIndex(where: { $0.sessionId == sessionId }) else { return }
        let clampedTarget = max(0, min(toIndex, sessions.count - 1))
        guard fromIndex != clampedTarget else { return }

        var reordered = sessions
        let item = reordered.remove(at: fromIndex)
        reordered.insert(item, at: clampedTarget)
        sessions = reordered
        manualOrder = reordered.map(\.sessionId)
        recalculateStats()
        onFleetChange?()
    }

    // MARK: - Archive / Delete

    public func archiveSession(id: String) {
        guard let session = session(byId: id) else { return }
        session.isArchived = true
        recalculateStats()
        onFleetChange?()
    }

    public func unarchiveSession(id: String) {
        guard let session = session(byId: id) else { return }
        session.isArchived = false
        recalculateStats()
        onFleetChange?()
    }

    /// Permanently removes the session from the fleet (calls unregister internally).
    public func deleteSession(id: String) {
        unregister(sessionId: id)
    }

    // MARK: - Refresh

    public func refresh() {
        sessions = applyOrder(to: sessions)
        recalculateStats()
        checkForStateChanges()
        onFleetChange?()
    }

    // MARK: - State-change notification dispatch

    /// Compares the current state of every session against the last recorded
    /// state. Fires a notification only on genuine transitions INTO a noteworthy
    /// state. Rate-limiting is enforced inside `NotificationManaging`.
    private func checkForStateChanges() {
        for session in sessions {
            let currentState = session.state
            let previousState = lastNotifiedStates[session.sessionId]

            // Ignore sessions whose state has not changed.
            guard currentState != previousState else { continue }
            lastNotifiedStates[session.sessionId] = currentState

            switch currentState {
            case .needsInput:
                notificationManager.notifyNeedsInput(
                    sessionId: session.sessionId,
                    sessionName: session.sessionName
                )
            case .error:
                notificationManager.notifyError(
                    sessionId: session.sessionId,
                    sessionName: session.sessionName,
                    error: "Session encountered an error"
                )
            case .inactive:
                // Notify completion only when transitioning FROM an active state.
                if previousState == .working || previousState == .needsInput {
                    notificationManager.notifySessionCompleted(
                        sessionId: session.sessionId,
                        sessionName: session.sessionName
                    )
                }
            case .working:
                // Resuming work after input/error is not noteworthy.
                break
            }
        }
    }

    // MARK: - Private

    /// Applies `manualOrder` when present; otherwise falls back to priority sorting.
    private func applyOrder(to input: [any AgentSessionRepresentable]) -> [any AgentSessionRepresentable] {
        guard let order = manualOrder else {
            return sorter.sorted(input)
        }
        // Place sessions according to the stored order; append any newcomers at the end.
        var lookup: [String: any AgentSessionRepresentable] = [:]
        for session in input { lookup[session.sessionId] = session }
        var result: [any AgentSessionRepresentable] = order.compactMap { lookup[$0] }
        let known = Set(order)
        let newcomers = input.filter { !known.contains($0.sessionId) }
        result.append(contentsOf: newcomers)
        return result
    }

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
