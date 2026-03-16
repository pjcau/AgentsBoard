// MARK: - API Server
// Hummingbird HTTP server with REST routes + WebSocket support.

import Foundation
import Hummingbird
import HummingbirdWebSocket

enum APIServer {

    static func build(
        compositionRoot: ServerCompositionRoot,
        host: String,
        port: Int
    ) throws -> some ApplicationProtocol {
        let router = Router()

        // Middleware
        router.middlewares.add(LocalhostGuard())

        // Health check
        router.get("/health") { _, _ in
            return Response(status: .ok, body: .init(byteBuffer: .init(string: "{\"status\":\"ok\"}")))
        }

        // REST API routes
        SessionRoutes.register(on: router, compositionRoot: compositionRoot)
        FleetRoutes.register(on: router, compositionRoot: compositionRoot)
        ActivityRoutes.register(on: router, compositionRoot: compositionRoot)
        CostRoutes.register(on: router, compositionRoot: compositionRoot)
        ConfigRoutes.register(on: router, compositionRoot: compositionRoot)
        TerminalRoutes.register(on: router, compositionRoot: compositionRoot)

        let app = Application(
            router: router,
            configuration: .init(address: .hostname(host, port: port))
        )

        return app
    }
}
