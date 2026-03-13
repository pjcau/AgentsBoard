// MARK: - Activity Logger Tests

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - ActivityEventType Tests

@Suite("ActivityEventType")
struct ActivityEventTypeTests {
    @Test func allTypes() {
        let types: [ActivityEventType] = [
            .fileChanged, .commandRun, .error, .costDelta,
            .approval, .subAgentSpawn, .stateChange
        ]
        #expect(types.count == 7)
    }
}

// MARK: - ActivityEvent Tests

@Suite("ActivityEvent")
struct ActivityEventTests {
    @Test func creation() {
        let event = ActivityEvent(
            sessionId: "s1", eventType: .fileChanged,
            details: "Modified auth.swift", cost: 0.01
        )
        #expect(event.sessionId == "s1")
        #expect(event.eventType == .fileChanged)
        #expect(event.details == "Modified auth.swift")
        #expect(event.cost == 0.01)
    }

    @Test func uniqueIds() {
        let e1 = ActivityEvent(sessionId: "s1", eventType: .error, details: "A")
        let e2 = ActivityEvent(sessionId: "s1", eventType: .error, details: "B")
        #expect(e1.id != e2.id)
    }

    @Test func codable() throws {
        let event = ActivityEvent(
            sessionId: "s1", eventType: .error,
            details: "Compile error"
        )
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(ActivityEvent.self, from: data)
        #expect(decoded.id == event.id)
        #expect(decoded.eventType == .error)
    }
}

// MARK: - ActivityLogger Tests

@Suite("ActivityLogger")
struct ActivityLoggerTests {
    private func makeLogger() -> ActivityLogger {
        ActivityLogger(persistence: MockPersistence())
    }

    @Test func initiallyEmpty() {
        let logger = makeLogger()
        #expect(logger.allEvents.isEmpty)
    }

    @Test func logEvent() {
        let logger = makeLogger()
        logger.log(ActivityEvent(sessionId: "s1", eventType: .commandRun, details: "swift build"))
        #expect(logger.allEvents.count == 1)
    }

    @Test func logMultipleEvents() {
        let logger = makeLogger()
        for i in 0..<5 {
            logger.log(ActivityEvent(sessionId: "s\(i)", eventType: .stateChange, details: "State \(i)"))
        }
        #expect(logger.allEvents.count == 5)
    }

    @Test func filterBySession() {
        let logger = makeLogger()
        logger.log(ActivityEvent(sessionId: "s1", eventType: .commandRun, details: "A"))
        logger.log(ActivityEvent(sessionId: "s2", eventType: .commandRun, details: "B"))
        logger.log(ActivityEvent(sessionId: "s1", eventType: .fileChanged, details: "C"))

        let s1Events = logger.events(forSession: "s1")
        #expect(s1Events.count == 2)

        let s2Events = logger.events(forSession: "s2")
        #expect(s2Events.count == 1)
    }

    @Test func filterByType() {
        let logger = makeLogger()
        logger.log(ActivityEvent(sessionId: "s1", eventType: .error, details: "E1"))
        logger.log(ActivityEvent(sessionId: "s1", eventType: .commandRun, details: "C1"))
        logger.log(ActivityEvent(sessionId: "s1", eventType: .error, details: "E2"))

        let errors = logger.events(ofType: .error)
        #expect(errors.count == 2)
    }

    @Test func filterSinceDate() {
        let logger = makeLogger()
        let now = Date()
        logger.log(ActivityEvent(sessionId: "s1", eventType: .commandRun, details: "Now"))

        let recent = logger.events(since: now.addingTimeInterval(-60))
        #expect(recent.count == 1)

        let future = logger.events(since: now.addingTimeInterval(60))
        #expect(future.isEmpty)
    }
}
