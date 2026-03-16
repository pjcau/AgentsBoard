// MARK: - Localhost Guard Middleware
// Rejects connections from non-localhost origins for security.

import Hummingbird

struct LocalhostGuard: RouterMiddleware {
    typealias Context = BasicRequestContext

    func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        // In production, validate the peer address.
        // For Hummingbird 2.x, the server binds to localhost by default,
        // so non-local connections are already rejected at the transport layer.
        // This middleware is a defense-in-depth check on the Host header.
        if let host = request.headers[.host] {
            let hostValue = String(host)
            let isLocal = hostValue.hasPrefix("localhost") ||
                          hostValue.hasPrefix("127.0.0.1") ||
                          hostValue.hasPrefix("[::1]")
            if !isLocal {
                return Response(
                    status: .forbidden,
                    body: .init(byteBuffer: .init(string: "{\"error\":\"Non-localhost access forbidden\"}"))
                )
            }
        }
        return try await next(request, context)
    }
}
