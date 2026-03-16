// MARK: - WebSocket Event Broker
// Manages connected WebSocket clients and broadcasts events by channel.

import Foundation

public actor EventBroker {

    // MARK: - Types

    struct Client: Hashable {
        let id: String
        let send: @Sendable (String) async -> Void

        static func == (lhs: Client, rhs: Client) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    // MARK: - State

    private var subscriptions: [String: Set<Client>] = [:]

    // MARK: - Client Management

    func subscribe(_ client: Client, to channel: String) {
        subscriptions[channel, default: []].insert(client)
    }

    func unsubscribe(_ client: Client) {
        for key in subscriptions.keys {
            subscriptions[key]?.remove(client)
        }
    }

    // MARK: - Broadcasting

    func broadcast(event: WSEvent) async {
        guard let encoder = try? JSONEncoder().encode(event),
              let json = String(data: encoder, encoding: .utf8) else { return }

        let clients = subscriptions[event.channel] ?? []
        for client in clients {
            await client.send(json)
        }
    }
}
