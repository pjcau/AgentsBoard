// MARK: - Fleet Routes
// REST endpoints for fleet-wide statistics.

import Foundation
import Hummingbird
import AgentsBoardCore

enum FleetRoutes {

    static func register(on router: Router<BasicRequestContext>, compositionRoot: ServerCompositionRoot) {
        let group = router.group("api/v1/fleet")
        let fleet = compositionRoot.fleetManager

        // GET /api/v1/fleet/stats
        group.get("stats") { _, _ -> Response in
            let stats = fleet.stats
            let dto = FleetStatsDTO(
                totalSessions: stats.totalSessions,
                activeSessions: stats.activeSessions,
                needsInputCount: stats.needsInputCount,
                errorCount: stats.errorCount,
                totalCost: "\(stats.totalCost)",
                costByProvider: stats.costByProvider.reduce(into: [:]) { $0[$1.key.rawValue] = "\($1.value)" },
                sessionsByState: stats.sessionsByState.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value }
            )
            return try jsonResponse(dto)
        }
    }
}

struct FleetStatsDTO: Codable {
    let totalSessions: Int
    let activeSessions: Int
    let needsInputCount: Int
    let errorCount: Int
    let totalCost: String
    let costByProvider: [String: String]
    let sessionsByState: [String: Int]
}
