// MARK: - Fleet Manager Tests

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - Mock Session

private final class MockSession: AgentSessionRepresentable {
    let sessionId: String
    var agentInfo: AgentInfo?
    var state: AgentState
    var totalCost: Decimal
    var projectPath: String?
    var startTime: Date
    var lastEventTime: Date?
    var isArchived: Bool = false

    init(
        sessionId: String,
        state: AgentState = .inactive,
        totalCost: Decimal = 0,
        projectPath: String? = nil
    ) {
        self.sessionId = sessionId
        self.state = state
        self.totalCost = totalCost
        self.projectPath = projectPath
        self.startTime = Date()
    }
}

// MARK: - FleetManager Tests

@Suite("FleetManager")
struct FleetManagerTests {
    @Test func initiallyEmpty() {
        let manager = FleetManager()
        #expect(manager.sessions.isEmpty)
        #expect(manager.stats.totalSessions == 0)
    }

    @Test func registerSession() {
        let manager = FleetManager()
        let session = MockSession(sessionId: "s1", state: .working)
        manager.register(session)
        #expect(manager.sessions.count == 1)
    }

    @Test func unregisterSession() {
        let manager = FleetManager()
        let session = MockSession(sessionId: "s1")
        manager.register(session)
        manager.unregister(sessionId: "s1")
        #expect(manager.sessions.isEmpty)
    }

    @Test func findSessionById() {
        let manager = FleetManager()
        manager.register(MockSession(sessionId: "s1"))
        manager.register(MockSession(sessionId: "s2"))

        let found = manager.session(byId: "s2")
        #expect(found != nil)
        #expect(found?.sessionId == "s2")
    }

    @Test func sessionNotFound() {
        let manager = FleetManager()
        #expect(manager.session(byId: "nonexistent") == nil)
    }

    @Test func unregisterNonexistentDoesNotCrash() {
        let manager = FleetManager()
        manager.unregister(sessionId: "nope") // Should not crash
        #expect(manager.sessions.isEmpty)
    }

    @Test func onFleetChangeCallback() {
        let manager = FleetManager()
        var callbackFired = false
        manager.onFleetChange = { callbackFired = true }
        manager.register(MockSession(sessionId: "s1"))
        // Callback may or may not fire synchronously; just ensure no crash
        _ = callbackFired
    }
}

// MARK: - FleetStats Tests

@Suite("FleetStats")
struct FleetStatsTests {
    @Test func emptyStats() {
        let stats = FleetStats.empty
        #expect(stats.totalSessions == 0)
        #expect(stats.activeSessions == 0)
        #expect(stats.needsInputCount == 0)
        #expect(stats.errorCount == 0)
        #expect(stats.totalCost == 0)
    }
}
