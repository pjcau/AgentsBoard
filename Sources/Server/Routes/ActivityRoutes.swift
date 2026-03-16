// MARK: - Activity Routes
// REST endpoints for activity log.

import Foundation
import Hummingbird
import AgentsBoardCore

enum ActivityRoutes {

    static func register(on router: Router<BasicRequestContext>, compositionRoot: ServerCompositionRoot) {
        let group = router.group("api/v1/activity")
        let logger = compositionRoot.activityLogger

        // GET /api/v1/activity
        group.get { request, _ -> Response in
            let limitStr = request.uri.queryParameters.get("limit")
            let limit = limitStr.flatMap(Int.init) ?? 100
            let sessionId = request.uri.queryParameters.get("session")

            let events: [ActivityEvent]
            if let sessionId {
                events = Array(logger.events(forSession: sessionId).prefix(limit))
            } else {
                events = Array(logger.allEvents.prefix(limit))
            }

            let dtos = events.map { ActivityEventDTO(from: $0) }
            return try jsonResponse(dtos)
        }
    }
}

struct ActivityEventDTO: Codable {
    let id: String
    let sessionId: String
    let eventType: String
    let details: String
    let timestamp: String
    let cost: String?

    init(from event: ActivityEvent) {
        self.id = event.id.uuidString
        self.sessionId = event.sessionId
        self.eventType = event.eventType.rawValue
        self.details = event.details
        self.timestamp = ISO8601DateFormatter().string(from: event.timestamp)
        self.cost = event.cost.map { "\($0)" }
    }
}
