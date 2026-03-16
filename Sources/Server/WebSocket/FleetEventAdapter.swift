// MARK: - Fleet Event Adapter
// Bridges FleetManaging onChange to WebSocket broadcasts.

import Foundation
import AgentsBoardCore

final class FleetEventAdapter {

    private let fleet: any FleetManaging
    private let broker: EventBroker

    init(fleet: any FleetManaging, broker: EventBroker) {
        self.fleet = fleet
        self.broker = broker
        wireCallbacks()
    }

    private func wireCallbacks() {
        fleet.onFleetChange = { [weak self] in
            guard let self else { return }
            Task {
                let sessions = self.fleet.sessions.map { session in
                    AnyCodableValue.dict([
                        "sessionId": .string(session.sessionId),
                        "sessionName": .string(session.sessionName),
                        "state": .string(session.state.rawValue),
                    ])
                }
                await self.broker.broadcast(event: WSEvent(
                    channel: "fleet",
                    event: "fleet_updated",
                    data: .array(sessions)
                ))
            }
        }
    }
}
