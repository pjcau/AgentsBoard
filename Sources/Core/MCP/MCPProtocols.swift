// MARK: - MCP Protocols

import Foundation

/// A tool that can be registered with the MCP server (OCP: add tools without modifying server).
public protocol MCPToolRegistrable {
    var name: String { get }
    var description: String { get }
    var inputSchema: [String: Any] { get }

    func execute(params: [String: Any]) async throws -> Any
}

/// Manages the MCP JSON-RPC 2.0 server lifecycle.
public protocol MCPServerManaging: AnyObject {
    var isRunning: Bool { get }

    func start() throws
    func stop()
    func register(tool: any MCPToolRegistrable)
    func unregister(toolName: String)
}
