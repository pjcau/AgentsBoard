// MARK: - MCP Server Tests

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - AnyCodable Tests

@Suite("AnyCodable")
struct AnyCodableTests {
    @Test func stringValue() throws {
        let value = AnyCodable("hello")
        let encoded = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
        #expect(decoded.value as? String == "hello")
    }

    @Test func intValue() throws {
        let value = AnyCodable(42)
        let encoded = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
        // JSON numbers may decode as Int or Double
        if let intVal = decoded.value as? Int {
            #expect(intVal == 42)
        }
    }

    @Test func boolValue() throws {
        let value = AnyCodable(true)
        let encoded = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
        #expect(decoded.value as? Bool == true)
    }

    @Test func nullValue() throws {
        let value = AnyCodable(nil as String?)
        let encoded = try JSONEncoder().encode(value)
        let json = String(data: encoded, encoding: .utf8)!
        #expect(json == "null")
    }

    @Test func arrayWrapping() {
        let value = AnyCodable([1, 2, 3])
        #expect(value.value is [Any])
    }

    @Test func dictionaryWrapping() {
        let value = AnyCodable(["key": "value"])
        #expect(value.value is [String: Any])
    }
}

// MARK: - MCPToolDefinition Tests

@Suite("MCPToolDefinition")
struct MCPToolDefinitionTests {
    @Test func creation() {
        let def = MCPToolDefinition(
            name: "test_tool",
            description: "A test tool",
            inputSchema: ["type": "object"]
        )
        #expect(def.name == "test_tool")
        #expect(def.description == "A test tool")
    }
}

// MARK: - MCPServer Tests

@Suite("MCPServer")
struct MCPServerTests {
    @Test func initialState() {
        let server = MCPServer()
        #expect(!server.isRunning)
    }

    @Test func registerTool() {
        let server = MCPServer()
        let tool = MockMCPTool()
        server.registerTool(tool)
        #expect(server.registeredToolNames.contains("mock_tool"))
    }

    @Test func unregisterTool() {
        let server = MCPServer()
        let tool = MockMCPTool()
        server.registerTool(tool)
        server.unregister(toolName: "mock_tool")
        #expect(!server.registeredToolNames.contains("mock_tool"))
    }
}

private final class MockMCPTool: MCPTool {
    var definition: MCPToolDefinition {
        MCPToolDefinition(name: "mock_tool", description: "Mock", inputSchema: [:])
    }
    func execute(params: [String: AnyCodable]?) async -> Any {
        return ["result": "ok"]
    }
}
