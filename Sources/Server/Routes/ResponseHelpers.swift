// MARK: - Response Helpers
// Shared JSON encoding utilities for route handlers.

import Foundation
import Hummingbird

func jsonResponse<T: Encodable>(_ value: T) throws -> Response {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(value)
    var headers = HTTPFields()
    headers[.contentType] = "application/json"
    return Response(
        status: .ok,
        headers: headers,
        body: .init(byteBuffer: .init(data: data))
    )
}

func notFound(_ message: String) -> Response {
    Response(
        status: .notFound,
        body: .init(byteBuffer: .init(string: "{\"error\":\"\(message)\"}"))
    )
}

func badRequest(_ message: String) -> Response {
    Response(
        status: .badRequest,
        body: .init(byteBuffer: .init(string: "{\"error\":\"\(message)\"}"))
    )
}
