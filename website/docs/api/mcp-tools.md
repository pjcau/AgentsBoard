---
sidebar_position: 4
---

# MCP Tools API

## Tool Protocol

```swift
public protocol MCPTool {
    var definition: MCPToolDefinition { get }
    func execute(params: [String: AnyCodable]?) async -> Any
}

public struct MCPToolDefinition {
    let name: String
    let description: String
    let inputSchema: [String: Any]
}
```

## Built-in Tools

### list_sessions

Lists all active agent sessions.

**Parameters**: None

**Response**:
```json
{
  "sessions": [
    {
      "sessionId": "abc-123",
      "provider": "claude",
      "state": "working",
      "cost": 0.45
    }
  ]
}
```

### get_fleet_stats

Returns aggregate fleet statistics.

**Parameters**: None

**Response**:
```json
{
  "totalSessions": 5,
  "activeSessions": 3,
  "needsInput": 1,
  "errors": 0,
  "totalCost": 12.30
}
```

### send_input

Sends text input to a specific session.

**Parameters**:
```json
{
  "sessionId": "abc-123",
  "text": "yes, approve the changes"
}
```

### get_activity_log

Returns recent activity events.

**Parameters**:
```json
{
  "limit": 50,
  "sessionId": "abc-123"  // optional filter
}
```

### get_agent_states

Returns current state of all agents.

**Parameters**: None
