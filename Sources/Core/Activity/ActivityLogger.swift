// MARK: - Activity Logger (Step 6.2)
// Structured timeline of agent actions.

import Foundation
import Observation

/// Activity event types.
public enum ActivityEventType: String, Codable, Sendable {
    case fileChanged
    case commandRun
    case error
    case costDelta
    case approval
    case subAgentSpawn
    case stateChange
}

/// A single activity event.
public struct ActivityEvent: Codable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let sessionId: String
    public let eventType: ActivityEventType
    public let details: String
    public let cost: Decimal?

    public init(sessionId: String, eventType: ActivityEventType, details: String, cost: Decimal? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.sessionId = sessionId
        self.eventType = eventType
        self.details = details
        self.cost = cost
    }
}

/// Logs and queries activity events.
@Observable
public final class ActivityLogger {

    private var events: [ActivityEvent] = []
    private let persistence: any PersistenceProviding
    private let maxInMemory = 10000

    public init(persistence: any PersistenceProviding) {
        self.persistence = persistence
    }

    // MARK: - Log

    public func log(_ event: ActivityEvent) {
        events.append(event)
        if events.count > maxInMemory {
            events.removeFirst(events.count - maxInMemory)
        }
        try? persistence.save(event, in: "activity_events")
    }

    public func logHookEvent(_ hookEvent: HookEvent, sessionId: String) {
        let event: ActivityEvent
        switch hookEvent {
        case .fileWrite(let path, _):
            event = ActivityEvent(sessionId: sessionId, eventType: .fileChanged, details: "Modified: \(path)")
        case .fileRead(let path):
            event = ActivityEvent(sessionId: sessionId, eventType: .fileChanged, details: "Read: \(path)")
        case .commandExec(let cmd, let exitCode):
            let type: ActivityEventType = exitCode == 0 ? .commandRun : .error
            event = ActivityEvent(sessionId: sessionId, eventType: type, details: "\(cmd) (exit: \(exitCode))")
        case .toolUse(let name, _, _):
            event = ActivityEvent(sessionId: sessionId, eventType: .commandRun, details: "Tool: \(name)")
        case .costDelta(_, _, let cost):
            event = ActivityEvent(sessionId: sessionId, eventType: .costDelta, details: "Cost: $\(cost)", cost: cost)
        case .approval(let tool, let status):
            event = ActivityEvent(sessionId: sessionId, eventType: .approval, details: "\(tool): \(status.rawValue)")
        case .subAgentSpawn(let id):
            event = ActivityEvent(sessionId: sessionId, eventType: .subAgentSpawn, details: "Sub-agent: \(id)")
        }
        log(event)
    }

    // MARK: - Query

    public func events(since date: Date) -> [ActivityEvent] {
        events.filter { $0.timestamp >= date }
    }

    public func events(forSession sessionId: String) -> [ActivityEvent] {
        events.filter { $0.sessionId == sessionId }
    }

    public func events(ofType type: ActivityEventType) -> [ActivityEvent] {
        events.filter { $0.eventType == type }
    }

    public var allEvents: [ActivityEvent] { events }
}
