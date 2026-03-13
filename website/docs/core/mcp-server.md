---
sidebar_position: 7
---

# MCP Server

AgentsBoard exposes a JSON-RPC 2.0 server implementing the Model Context Protocol (MCP).

## Protocol

Communication uses stdio transport with JSON-RPC 2.0:

```json
// Request
{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "list_sessions"}}

// Response
{"jsonrpc": "2.0", "id": 1, "result": {"sessions": [...]}}
```

## Built-in Tools

| Tool | Description |
|------|-------------|
| `list_sessions` | List all active agent sessions |
| `get_fleet_stats` | Aggregate fleet statistics |
| `get_activity_log` | Recent activity events |
| `send_input` | Send text to a specific session |
| `get_agent_states` | Snapshot of all agent states |

## Adding Custom Tools (OCP)

```swift
// 1. Implement the MCPTool protocol
final class MyTool: MCPTool {
    var definition: MCPToolDefinition {
        MCPToolDefinition(
            name: "my_tool",
            description: "Does something useful",
            inputSchema: ["type": "object", "properties": [...]]
        )
    }

    func execute(params: [String: AnyCodable]?) async -> Any {
        return ["result": "success"]
    }
}

// 2. Register at runtime
server.registerTool(MyTool())
```

## MCPServer Usage

```swift
let server = MCPServer()
server.registerTool(ListSessionsTool(fleet: fleet))
server.registerTool(GetFleetStatsTool(fleet: fleet))
try server.start()
```
