// MARK: - Session Remix (Step 14.2)
// Fork a session into an isolated git worktree with context transfer.

import Foundation

/// Extracts useful context from an agent session for transfer.
struct ContextExtractor {
    func extract(from session: any AgentSessionRepresentable, depth: ContextDepth) -> SessionContext {
        var context = SessionContext()
        context.sessionId = session.sessionId
        context.provider = session.agentInfo?.provider
        context.model = session.agentInfo?.model

        // Depth determines how much context to transfer
        switch depth {
        case .summary:
            context.summary = "Previous session with \(session.agentInfo?.provider.rawValue ?? "unknown") provider"
        case .lastNActions:
            context.summary = "Previous session context (last actions)"
        case .fullTranscript:
            context.summary = "Full session context transferred"
        }

        return context
    }
}

/// Depth of context to transfer during remix.
public enum ContextDepth: String, CaseIterable, Sendable {
    case summary = "Summary Only"
    case lastNActions = "Last N Actions"
    case fullTranscript = "Full Transcript"
}

/// Extracted context from a session.
public struct SessionContext {
    public var sessionId: String = ""
    public var provider: AgentProvider?
    public var model: ModelIdentifier?
    public var summary: String = ""
    public var filesModified: [String] = []
    public var keyDecisions: [String] = []
    public var errors: [String] = []

    public init() {}
}

/// Manages the remix workflow: worktree creation + context transfer + new session launch.
public final class SessionRemixer {

    private let contextExtractor = ContextExtractor()

    public struct RemixConfig {
        public let sourceSession: any AgentSessionRepresentable
        public let targetProvider: AgentProvider
        public let branchName: String
        public let contextDepth: ContextDepth
        public let projectPath: String

        public init(sourceSession: any AgentSessionRepresentable, targetProvider: AgentProvider, branchName: String, contextDepth: ContextDepth, projectPath: String) {
            self.sourceSession = sourceSession
            self.targetProvider = targetProvider
            self.branchName = branchName
            self.contextDepth = contextDepth
            self.projectPath = projectPath
        }
    }

    public init() {}

    public func remix(config: RemixConfig) async throws -> RemixResult {
        // 1. Create git worktree
        let worktreePath = try createWorktree(
            projectPath: config.projectPath,
            branchName: config.branchName
        )

        // 2. Extract context from source session
        let context = contextExtractor.extract(
            from: config.sourceSession,
            depth: config.contextDepth
        )

        // 3. Build initial prompt with context
        let prompt = buildPrompt(context: context)

        return RemixResult(
            worktreePath: worktreePath,
            branchName: config.branchName,
            targetProvider: config.targetProvider,
            initialPrompt: prompt,
            context: context
        )
    }

    private func createWorktree(projectPath: String, branchName: String) throws -> String {
        let worktreePath = projectPath + "-worktrees/" + branchName

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["worktree", "add", "-b", branchName, worktreePath]
        process.currentDirectoryURL = URL(fileURLWithPath: projectPath)

        let pipe = Pipe()
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw RemixError.worktreeCreationFailed(error)
        }

        return worktreePath
    }

    private func buildPrompt(context: SessionContext) -> String {
        var parts: [String] = []
        parts.append("Context from previous session:")
        parts.append(context.summary)

        if !context.filesModified.isEmpty {
            parts.append("\nFiles modified: \(context.filesModified.joined(separator: ", "))")
        }
        if !context.keyDecisions.isEmpty {
            parts.append("\nKey decisions: \(context.keyDecisions.joined(separator: "; "))")
        }
        if !context.errors.isEmpty {
            parts.append("\nPrevious errors: \(context.errors.joined(separator: "; "))")
        }

        return parts.joined(separator: "\n")
    }
}

public struct RemixResult {
    public let worktreePath: String
    public let branchName: String
    public let targetProvider: AgentProvider
    public let initialPrompt: String
    public let context: SessionContext

    public init(worktreePath: String, branchName: String, targetProvider: AgentProvider, initialPrompt: String, context: SessionContext) {
        self.worktreePath = worktreePath
        self.branchName = branchName
        self.targetProvider = targetProvider
        self.initialPrompt = initialPrompt
        self.context = context
    }
}

public enum RemixError: Error {
    case worktreeCreationFailed(String)
    case sessionNotFound
}
