// MARK: - AgentsBoardServer Entry Point
// Headless HTTP + WebSocket server exposing Core APIs on localhost:19850.

import Foundation
import Hummingbird

@main
struct AgentsBoardServerMain {
    static func main() async throws {
        let host = ProcessInfo.processInfo.environment["AGENTSBOARD_HOST"] ?? "127.0.0.1"
        let port = Int(ProcessInfo.processInfo.environment["AGENTSBOARD_PORT"] ?? "19850") ?? 19850

        let compositionRoot = ServerCompositionRoot()
        let app = try APIServer.build(compositionRoot: compositionRoot, host: host, port: port)

        print("[AgentsBoardServer] Starting on \(host):\(port)")
        try await app.runService()
    }
}
