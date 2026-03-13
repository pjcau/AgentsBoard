// MARK: - MCP Tools (Step 13.1)
// Individual MCP tools implementing the MCPTool protocol (OCP).

import Foundation

// MARK: - List Sessions Tool

final class ListSessionsTool: MCPTool {
    private let fleetManager: any FleetManaging

    init(fleetManager: any FleetManaging) { self.fleetManager = fleetManager }

    var definition: MCPToolDefinition {
        MCPToolDefinition(
            name: "list_sessions",
            description: "List all active agent sessions with their status",
            inputSchema: [
                "type": "object",
                "properties": [
                    "state": ["type": "string", "description": "Filter by state: working, needsInput, error, inactive"],
                    "provider": ["type": "string", "description": "Filter by provider: claude, codex, aider, gemini"]
                ]
            ]
        )
    }

    func execute(params: [String: AnyCodable]?) async -> Any {
        let sessions = fleetManager.sessions.map { session -> [String: AnyCodable] in
            [
                "sessionId": AnyCodable(session.sessionId),
                "state": AnyCodable(session.state.rawValue),
                "provider": AnyCodable(session.agentInfo?.provider.rawValue ?? "unknown"),
                "model": AnyCodable(session.agentInfo?.model.name ?? "unknown"),
                "cost": AnyCodable("\(session.totalCost)")
            ]
        }
        return ["sessions": AnyCodable(sessions)]
    }
}

// MARK: - Get Fleet Stats Tool

final class GetFleetStatsTool: MCPTool {
    private let fleetManager: any FleetManaging

    init(fleetManager: any FleetManaging) { self.fleetManager = fleetManager }

    var definition: MCPToolDefinition {
        MCPToolDefinition(
            name: "get_fleet_stats",
            description: "Get aggregate fleet statistics",
            inputSchema: ["type": "object", "properties": [:] as [String: Any]]
        )
    }

    func execute(params: [String: AnyCodable]?) async -> Any {
        let stats = fleetManager.stats
        return [
            "totalSessions": AnyCodable(stats.totalSessions),
            "activeSessions": AnyCodable(stats.activeSessions),
            "needsInputCount": AnyCodable(stats.needsInputCount),
            "errorCount": AnyCodable(stats.errorCount),
            "totalCost": AnyCodable("\(stats.totalCost)")
        ] as [String: AnyCodable]
    }
}

// MARK: - Get Activity Log Tool

final class GetActivityLogTool: MCPTool {
    private let activityLogger: ActivityLogger

    init(activityLogger: ActivityLogger) { self.activityLogger = activityLogger }

    var definition: MCPToolDefinition {
        MCPToolDefinition(
            name: "get_activity_log",
            description: "Get recent activity events from agent sessions",
            inputSchema: [
                "type": "object",
                "properties": [
                    "limit": ["type": "integer", "description": "Max events to return (default 50)"],
                    "sessionId": ["type": "string", "description": "Filter by session ID"]
                ]
            ]
        )
    }

    func execute(params: [String: AnyCodable]?) async -> Any {
        let limit = (params?["limit"]?.value as? Int) ?? 50
        let sessionId = params?["sessionId"]?.value as? String

        let events: [ActivityEvent]
        if let sessionId {
            events = Array(activityLogger.events(forSession: sessionId).prefix(limit))
        } else {
            events = Array(activityLogger.allEvents.suffix(limit))
        }

        let result = events.map { event -> [String: AnyCodable] in
            [
                "timestamp": AnyCodable(ISO8601DateFormatter().string(from: event.timestamp)),
                "sessionId": AnyCodable(event.sessionId),
                "type": AnyCodable(event.eventType.rawValue),
                "details": AnyCodable(event.details)
            ]
        }
        return ["events": AnyCodable(result)]
    }
}

// MARK: - Send Input Tool

final class SendInputTool: MCPTool {
    private let fleetManager: any FleetManaging

    init(fleetManager: any FleetManaging) { self.fleetManager = fleetManager }

    var definition: MCPToolDefinition {
        MCPToolDefinition(
            name: "send_input",
            description: "Send text input to a specific agent session",
            inputSchema: [
                "type": "object",
                "properties": [
                    "sessionId": ["type": "string", "description": "Target session ID"],
                    "text": ["type": "string", "description": "Text to send"]
                ],
                "required": ["sessionId", "text"]
            ]
        )
    }

    func execute(params: [String: AnyCodable]?) async -> Any {
        guard let sessionId = params?["sessionId"]?.value as? String,
              let text = params?["text"]?.value as? String else {
            return ["error": AnyCodable("Missing sessionId or text")]
        }

        if let session = fleetManager.sessions.first(where: { $0.sessionId == sessionId }) {
            if let controllable = session as? AgentControllable {
                controllable.sendInput(text + "\n")
                return ["success": AnyCodable(true)]
            }
            return ["error": AnyCodable("Session does not support input: \(sessionId)")]
        }
        return ["error": AnyCodable("Session not found: \(sessionId)")]
    }
}

// MARK: - Get Agent States Tool

final class GetAgentStatesTool: MCPTool {
    private let fleetManager: any FleetManaging

    init(fleetManager: any FleetManaging) { self.fleetManager = fleetManager }

    var definition: MCPToolDefinition {
        MCPToolDefinition(
            name: "get_agent_states",
            description: "Get the current state of all agents",
            inputSchema: ["type": "object", "properties": [:] as [String: Any]]
        )
    }

    func execute(params: [String: AnyCodable]?) async -> Any {
        let states = fleetManager.sessions.map { session -> [String: AnyCodable] in
            [
                "sessionId": AnyCodable(session.sessionId),
                "state": AnyCodable(session.state.rawValue),
                "provider": AnyCodable(session.agentInfo?.provider.rawValue ?? "unknown")
            ]
        }
        return ["agents": AnyCodable(states)]
    }
}
