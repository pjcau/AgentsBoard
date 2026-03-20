// MARK: - CORS Middleware
// Allows cross-origin requests from Tauri webview (tauri.localhost)
// and local development servers.

import Hummingbird

struct CORSMiddleware: RouterMiddleware {
    typealias Context = BasicRequestContext

    private let allowedOrigins = [
        "http://tauri.localhost",
        "https://tauri.localhost",
        "tauri://localhost",
        "http://localhost:5173",   // Vite dev server
        "http://localhost:19850",
        "http://127.0.0.1:19850",
    ]

    func handle(
        _ request: Request,
        context: Context,
        next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        let origin = request.headers[.origin] ?? ""

        let allowedOrigin: String
        if allowedOrigins.contains(origin) {
            allowedOrigin = origin
        } else if origin.hasPrefix("tauri://") {
            allowedOrigin = origin
        } else {
            allowedOrigin = allowedOrigins[0]
        }

        // Handle preflight OPTIONS
        if request.method == .options {
            return Response(
                status: .noContent,
                headers: [
                    .accessControlAllowOrigin: allowedOrigin,
                    .accessControlAllowMethods: "GET, POST, PUT, DELETE, OPTIONS",
                    .accessControlAllowHeaders: "Content-Type, Authorization",
                    .accessControlMaxAge: "86400",
                ]
            )
        }

        var response = try await next(request, context)
        response.headers[.accessControlAllowOrigin] = allowedOrigin
        response.headers[.accessControlAllowMethods] = "GET, POST, PUT, DELETE, OPTIONS"
        response.headers[.accessControlAllowHeaders] = "Content-Type, Authorization"
        return response
    }
}
