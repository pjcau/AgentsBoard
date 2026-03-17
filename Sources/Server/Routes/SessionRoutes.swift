// MARK: - Session Routes
// REST endpoints for session management.

import Foundation
import Hummingbird
import NIOCore
import AgentsBoardCore

enum SessionRoutes {

    static func register(on router: Router<BasicRequestContext>, compositionRoot: ServerCompositionRoot) {
        let group = router.group("api/v1/sessions")
        let fleet = compositionRoot.fleetManager

        // GET /api/v1/sessions
        group.get { _, _ -> Response in
            let sessions = fleet.sessions.map { SessionDTO(from: $0) }
            return try jsonResponse(sessions)
        }

        // GET /api/v1/sessions/:id
        group.get(":id") { _, context -> Response in
            guard let id = context.parameters.get("id"),
                  let session = fleet.session(byId: id) else {
                return notFound("Session not found")
            }
            return try jsonResponse(SessionDTO(from: session))
        }

        // POST /api/v1/sessions/:id/input
        group.post(":id/input") { request, context -> Response in
            guard let id = context.parameters.get("id"),
                  let session = fleet.session(byId: id) else {
                return notFound("Session not found")
            }
            var body = try await request.body.collect(upTo: 1_048_576)
            guard let bytes = body.readBytes(length: body.readableBytes),
                  let input = try? JSONDecoder().decode(InputDTO.self, from: Data(bytes)) else {
                return badRequest("Invalid input body")
            }
            session.sendInput(input.text)
            return Response(status: .ok, body: .init(byteBuffer: ByteBuffer(string: "{\"status\":\"sent\"}")))
        }

        // POST /api/v1/sessions/:id/archive
        group.post(":id/archive") { _, context -> Response in
            guard let id = context.parameters.get("id") else {
                return badRequest("Missing session ID")
            }
            fleet.archiveSession(id: id)
            return Response(status: .ok, body: .init(byteBuffer: ByteBuffer(string: "{\"status\":\"archived\"}")))
        }

        // DELETE /api/v1/sessions/:id
        group.delete(":id") { _, context -> Response in
            guard let id = context.parameters.get("id") else {
                return badRequest("Missing session ID")
            }
            fleet.deleteSession(id: id)
            return Response(status: .ok, body: .init(byteBuffer: ByteBuffer(string: "{\"status\":\"deleted\"}")))
        }
    }
}

// MARK: - DTOs

struct SessionDTO: Codable {
    let sessionId: String
    let sessionName: String
    let state: String
    let provider: String?
    let model: String?
    let totalCost: String
    let projectPath: String?
    let startTime: String
    let lastEventTime: String?
    let launchCommand: String?
    let gitBranch: String?
    let isArchived: Bool

    init(from session: any AgentSessionRepresentable) {
        self.sessionId = session.sessionId
        self.sessionName = session.sessionName
        self.state = session.state.rawValue
        self.provider = session.agentInfo?.provider.rawValue
        self.model = session.agentInfo?.model.name
        self.totalCost = "\(session.totalCost)"
        self.projectPath = session.projectPath
        self.startTime = ISO8601DateFormatter().string(from: session.startTime)
        self.lastEventTime = session.lastEventTime.map { ISO8601DateFormatter().string(from: $0) }
        self.launchCommand = session.launchCommand
        self.gitBranch = session.gitBranch
        self.isArchived = session.isArchived
    }
}

struct InputDTO: Codable {
    let text: String
}
