// MARK: - MCP Server (Step 13.1)
// JSON-RPC 2.0 server exposing AgentsBoard as a programmable tool.

import Foundation

// MARK: - Protocol Types

struct MCPRequest: Codable {
    let jsonrpc: String
    let id: Int?
    let method: String
    let params: [String: AnyCodable]?
}

struct MCPResponse: Codable {
    let jsonrpc: String
    let id: Int?
    let result: AnyCodable?
    let error: MCPError?

    static func success(id: Int?, result: Any) -> MCPResponse {
        MCPResponse(jsonrpc: "2.0", id: id, result: AnyCodable(result), error: nil)
    }

    static func error(id: Int?, code: Int, message: String) -> MCPResponse {
        MCPResponse(jsonrpc: "2.0", id: id, result: nil, error: MCPError(code: code, message: message))
    }
}

struct MCPError: Codable {
    let code: Int
    let message: String

    static let parseError = MCPError(code: -32700, message: "Parse error")
    static let methodNotFound = MCPError(code: -32601, message: "Method not found")
    static let invalidParams = MCPError(code: -32602, message: "Invalid params")
    static let internalError = MCPError(code: -32603, message: "Internal error")
}

/// Type-erased Codable wrapper for JSON-RPC params/results.
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) { self.value = value }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) { value = str }
        else if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let dict = try? container.decode([String: AnyCodable].self) { value = dict }
        else if let arr = try? container.decode([AnyCodable].self) { value = arr }
        else { value = Optional<Any>.none as Any }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let str = value as? String { try container.encode(str) }
        else if let int = value as? Int { try container.encode(int) }
        else if let double = value as? Double { try container.encode(double) }
        else if let bool = value as? Bool { try container.encode(bool) }
        else if let dict = value as? [String: AnyCodable] { try container.encode(dict) }
        else if let arr = value as? [AnyCodable] { try container.encode(arr) }
        else { try container.encodeNil() }
    }
}

// MARK: - MCP Tool Protocol

public struct MCPToolDefinition {
    public let name: String
    public let description: String
    public let inputSchema: [String: Any]

    public init(name: String, description: String, inputSchema: [String: Any]) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

public protocol MCPTool {
    var definition: MCPToolDefinition { get }
    func execute(params: [String: AnyCodable]?) async -> Any
}

// MARK: - MCP Server

public final class MCPServer: MCPServerManaging {

    private var tools: [String: MCPTool] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    public private(set) var isRunning: Bool = false

    public init() {}

    public func registerTool(_ tool: MCPTool) {
        tools[tool.definition.name] = tool
    }

    public func register(tool: any MCPToolRegistrable) {
        let wrapper = MCPToolRegistrableWrapper(registrable: tool)
        tools[tool.name] = wrapper
    }

    public func unregister(toolName: String) {
        tools.removeValue(forKey: toolName)
    }

    public var registeredToolNames: [String] { Array(tools.keys) }

    public func start() throws {
        isRunning = true
        // Read from stdin, write to stdout (stdio transport)
        Task {
            let handle = FileHandle.standardInput
            while true {
                let data = handle.availableData
                guard !data.isEmpty else { break }

                if let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !line.isEmpty {
                    await processLine(line)
                }
            }
        }
    }

    public func stop() {
        isRunning = false
        // Cleanup
    }

    private func processLine(_ line: String) async {
        guard let data = line.data(using: .utf8),
              let request = try? decoder.decode(MCPRequest.self, from: data) else {
            let response = MCPResponse.error(id: nil, code: -32700, message: "Parse error")
            send(response)
            return
        }

        let response: MCPResponse

        switch request.method {
        case "initialize":
            response = MCPResponse.success(id: request.id, result: [
                "protocolVersion": AnyCodable("2024-11-05"),
                "capabilities": AnyCodable(["tools": AnyCodable([:] as [String: AnyCodable])]),
                "serverInfo": AnyCodable([
                    "name": AnyCodable("agentsboard"),
                    "version": AnyCodable("1.0.0")
                ])
            ] as [String: AnyCodable])

        case "tools/list":
            let toolList = tools.values.map { tool -> [String: AnyCodable] in
                [
                    "name": AnyCodable(tool.definition.name),
                    "description": AnyCodable(tool.definition.description)
                ]
            }
            response = MCPResponse.success(id: request.id, result: ["tools": AnyCodable(toolList)])

        case "tools/call":
            guard let params = request.params,
                  let name = params["name"]?.value as? String else {
                response = MCPResponse.error(id: request.id, code: -32602, message: "Missing tool name")
                break
            }

            guard let tool = tools[name] else {
                response = MCPResponse.error(id: request.id, code: -32601, message: "Tool not found: \(name)")
                break
            }

            let toolParams = params["arguments"]?.value as? [String: AnyCodable]
            let result = await tool.execute(params: toolParams)
            response = MCPResponse.success(id: request.id, result: result)

        default:
            response = MCPResponse.error(id: request.id, code: -32601, message: "Method not found")
        }

        send(response)
    }

    private func send(_ response: MCPResponse) {
        guard let data = try? encoder.encode(response),
              let json = String(data: data, encoding: .utf8) else { return }
        print(json)
        fflush(stdout)
    }
}

/// Wraps an MCPToolRegistrable to conform to the internal MCPTool protocol.
private final class MCPToolRegistrableWrapper: MCPTool {
    private let registrable: any MCPToolRegistrable

    init(registrable: any MCPToolRegistrable) {
        self.registrable = registrable
    }

    var definition: MCPToolDefinition {
        MCPToolDefinition(
            name: registrable.name,
            description: registrable.description,
            inputSchema: registrable.inputSchema
        )
    }

    func execute(params: [String: AnyCodable]?) async -> Any {
        let rawParams: [String: Any] = params?.mapValues { $0.value } ?? [:]
        return (try? await registrable.execute(params: rawParams)) ?? ["error": "Execution failed"]
    }
}
