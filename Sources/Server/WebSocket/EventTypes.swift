// MARK: - WebSocket Event Types
// Structured events broadcast to WebSocket clients.

import Foundation

public struct WSEvent: Codable, Sendable {
    public let channel: String
    public let event: String
    public let data: AnyCodableValue
    public let timestamp: String

    public init(channel: String, event: String, data: AnyCodableValue, timestamp: Date = Date()) {
        self.channel = channel
        self.event = event
        self.data = data
        self.timestamp = ISO8601DateFormatter().string(from: timestamp)
    }
}

/// Lightweight type-erased Codable value for WebSocket event payloads.
public enum AnyCodableValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case dict([String: AnyCodableValue])
    case array([AnyCodableValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) { self = .string(str) }
        else if let int = try? container.decode(Int.self) { self = .int(int) }
        else if let double = try? container.decode(Double.self) { self = .double(double) }
        else if let bool = try? container.decode(Bool.self) { self = .bool(bool) }
        else if let dict = try? container.decode([String: AnyCodableValue].self) { self = .dict(dict) }
        else if let arr = try? container.decode([AnyCodableValue].self) { self = .array(arr) }
        else { self = .null }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .dict(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}
