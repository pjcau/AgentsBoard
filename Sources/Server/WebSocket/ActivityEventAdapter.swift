// MARK: - Activity Event Adapter
// Bridges ActivityLogger events to WebSocket broadcasts.

import Foundation
import AgentsBoardCore

final class ActivityEventAdapter {

    private let logger: ActivityLogger
    private let broker: EventBroker
    private var lastEventCount: Int = 0

    init(logger: ActivityLogger, broker: EventBroker) {
        self.logger = logger
        self.broker = broker
    }

    /// Polls for new events and broadcasts them. Call periodically.
    func checkForNewEvents() {
        let events = logger.allEvents
        guard events.count > lastEventCount else { return }
        let newEvents = events.suffix(from: lastEventCount)
        lastEventCount = events.count

        for event in newEvents {
            Task {
                await broker.broadcast(event: WSEvent(
                    channel: "activity",
                    event: "new_activity",
                    data: .dict([
                        "id": .string(event.id.uuidString),
                        "sessionId": .string(event.sessionId),
                        "eventType": .string(event.eventType.rawValue),
                        "details": .string(event.details),
                    ])
                ))
            }
        }
    }
}
