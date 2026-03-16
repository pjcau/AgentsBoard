// MARK: - Terminal Routes
// REST endpoint for terminal output retrieval.

import Foundation
import Hummingbird
import AgentsBoardCore

enum TerminalRoutes {

    static func register(on router: Router<BasicRequestContext>, compositionRoot: ServerCompositionRoot) {
        let group = router.group("api/v1/sessions")
        let fleet = compositionRoot.fleetManager

        // GET /api/v1/sessions/:id/output
        group.get(":id/output") { request, context -> Response in
            guard let id = context.parameters.get("id"),
                  let session = fleet.session(byId: id) else {
                return notFound("Session not found")
            }
            let linesStr = request.uri.queryParameters.get("lines")
            let maxLines = linesStr.flatMap(Int.init) ?? 500
            let output = session.outputText
            let lines = output.split(separator: "\n", omittingEmptySubsequences: false)
            let tail = lines.suffix(maxLines).joined(separator: "\n")
            let dto = TerminalOutputDTO(sessionId: id, output: tail, totalLines: lines.count)
            return try jsonResponse(dto)
        }
    }
}

struct TerminalOutputDTO: Codable {
    let sessionId: String
    let output: String
    let totalLines: Int
}
