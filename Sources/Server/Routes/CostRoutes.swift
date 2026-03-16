// MARK: - Cost Routes
// REST endpoints for cost tracking.

import Foundation
import Hummingbird
import AgentsBoardCore

enum CostRoutes {

    static func register(on router: Router<BasicRequestContext>, compositionRoot: ServerCompositionRoot) {
        let group = router.group("api/v1/costs")
        let costs = compositionRoot.costAggregator

        // GET /api/v1/costs
        group.get { _, _ -> Response in
            let total = costs.fleetTotalCost()
            let dto = CostSummaryDTO(fleetTotal: "\(total)")
            return try jsonResponse(dto)
        }

        // GET /api/v1/costs/session/:id
        group.get("session/:id") { _, context -> Response in
            guard let id = context.parameters.get("id") else {
                return badRequest("Missing session ID")
            }
            let total = costs.totalCost(forSession: id)
            return try jsonResponse(SessionCostDTO(sessionId: id, totalCost: "\(total)"))
        }

        // GET /api/v1/costs/history
        group.get("history") { request, _ -> Response in
            let fromStr = request.uri.queryParameters.get("from")
            let toStr = request.uri.queryParameters.get("to")
            let formatter = ISO8601DateFormatter()
            let from = fromStr.flatMap { formatter.date(from: $0) } ?? Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            let to = toStr.flatMap { formatter.date(from: $0) } ?? Date()
            let entries = costs.costHistory(from: from, to: to)
            let dtos = entries.map { CostEntryDTO(from: $0) }
            return try jsonResponse(dtos)
        }
    }
}

struct CostSummaryDTO: Codable {
    let fleetTotal: String
}

struct SessionCostDTO: Codable {
    let sessionId: String
    let totalCost: String
}

struct CostEntryDTO: Codable {
    let sessionId: String
    let provider: String
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let cost: String
    let timestamp: String

    init(from entry: CostEntry) {
        self.sessionId = entry.sessionId
        self.provider = entry.provider.rawValue
        self.model = entry.model.name
        self.inputTokens = entry.inputTokens
        self.outputTokens = entry.outputTokens
        self.cost = "\(entry.cost)"
        self.timestamp = ISO8601DateFormatter().string(from: entry.timestamp)
    }
}
