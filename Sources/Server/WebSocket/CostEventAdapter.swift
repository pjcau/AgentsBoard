// MARK: - Cost Event Adapter
// Bridges cost updates to WebSocket broadcasts.

import Foundation
import AgentsBoardCore

final class CostEventAdapter {

    private let costs: any CostAggregating
    private let broker: EventBroker

    init(costs: any CostAggregating, broker: EventBroker) {
        self.costs = costs
        self.broker = broker
        wireCallbacks()
    }

    private func wireCallbacks() {
        costs.onCostUpdate = { [weak self] in
            guard let self else { return }
            Task {
                let total = self.costs.fleetTotalCost()
                await self.broker.broadcast(event: WSEvent(
                    channel: "costs",
                    event: "cost_updated",
                    data: .dict([
                        "fleetTotal": .string("\(total)")
                    ])
                ))
            }
        }
    }
}
