// MARK: - Agent Domain Models

import Foundation

/// Identifies the AI coding agent provider.
public enum AgentProvider: String, Codable, CaseIterable, Sendable {
    case claude
    case codex
    case aider
    case gemini
    case custom
}

/// Represents the current operational state of an agent session.
public enum AgentState: String, Codable, Sendable {
    case working
    case needsInput
    case error
    case inactive
}

/// Identifies the specific LLM model an agent is using.
public struct ModelIdentifier: Codable, Equatable, Sendable {
    public let name: String
    public let provider: AgentProvider
    public let version: String?

    public init(name: String, provider: AgentProvider, version: String?) {
        self.name = name
        self.provider = provider
        self.version = version
    }
}

/// Complete identification of a detected agent session.
public struct AgentInfo: Codable, Sendable {
    public let provider: AgentProvider
    public let model: ModelIdentifier
    public let sessionId: String
    public let projectPath: String?
    public let startTime: Date
    public let launchCommand: String

    public init(provider: AgentProvider, model: ModelIdentifier, sessionId: String, projectPath: String?, startTime: Date, launchCommand: String) {
        self.provider = provider
        self.model = model
        self.sessionId = sessionId
        self.projectPath = projectPath
        self.startTime = startTime
        self.launchCommand = launchCommand
    }
}

/// A single cost data point from an agent session.
public struct CostEntry: Codable, Sendable, Identifiable {
    public let id: UUID
    public let provider: AgentProvider
    public let model: ModelIdentifier
    public let inputTokens: Int
    public let outputTokens: Int
    public let cost: Decimal
    public let timestamp: Date
    public let sessionId: String
    public let taskId: String?

    public init(
        provider: AgentProvider,
        model: ModelIdentifier,
        inputTokens: Int,
        outputTokens: Int,
        cost: Decimal,
        timestamp: Date = Date(),
        sessionId: String,
        taskId: String? = nil
    ) {
        self.id = UUID()
        self.provider = provider
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cost = cost
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.taskId = taskId
    }
}

/// Structured event received from Claude Code hooks (authoritative source).
public enum HookEvent: Sendable {
    case toolUse(name: String, input: String, output: String?)
    case fileRead(path: String)
    case fileWrite(path: String, diff: String?)
    case commandExec(command: String, exitCode: Int)
    case subAgentSpawn(id: String)
    case costDelta(inputTokens: Int, outputTokens: Int, cost: Decimal)
    case approval(tool: String, status: ApprovalStatus)

    public enum ApprovalStatus: String, Sendable {
        case approved
        case rejected
        case pending
    }
}
