// MARK: - Localhost Guard Middleware
// Defense-in-depth: the server already binds to localhost only.
// This middleware exists as a placeholder for future IP-based filtering.

import Hummingbird

struct LocalhostGuard: RouterMiddleware {
    typealias Context = BasicRequestContext

    func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        // The server binds to 127.0.0.1 by default, so non-local connections
        // are rejected at the transport layer. This middleware is a no-op
        // placeholder for future IP-based or auth-token filtering.
        return try await next(request, context)
    }
}
