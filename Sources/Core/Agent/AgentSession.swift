// MARK: - Agent Session (Step 3.2)
// Combines TerminalSession + AgentStateMachine + AgentInfo.

import Foundation
import Observation

@Observable
public final class AgentSession: AgentSessionRepresentable, TerminalDataReceiving {

    // MARK: - Properties

    public let sessionId: String
    public private(set) var agentInfo: AgentInfo?
    public private(set) var state: AgentState = .inactive
    public private(set) var totalCost: Decimal = 0
    public let projectPath: String?
    public let startTime: Date
    public private(set) var lastEventTime: Date?
    public var isArchived: Bool = false

    // MARK: - Internal Components

    let terminalSession: TerminalSession
    private var stateMachine: AgentStateMachine?
    private let costReporter: any AgentCostReportable
    private let providerRegistry: ProviderRegistry

    private var outputBuffer = ""
    private var hasDetected = false

    // MARK: - Init

    public init(
        terminalSession: TerminalSession,
        costReporter: any AgentCostReportable,
        providerRegistry: ProviderRegistry,
        projectPath: String? = nil
    ) {
        self.sessionId = terminalSession.sessionId
        self.terminalSession = terminalSession
        self.costReporter = costReporter
        self.providerRegistry = providerRegistry
        self.projectPath = projectPath
        self.startTime = Date()

        terminalSession.dataDelegate = self
    }

    // MARK: - TerminalDataReceiving

    public func terminalSession(_ session: any TerminalSessionManaging, didReceiveData data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }

        lastEventTime = Date()

        // Try to detect agent from initial output
        if !hasDetected {
            outputBuffer += text
            if outputBuffer.count > 2000 || outputBuffer.contains("\n") {
                tryDetect()
            }
        }

        // Feed to state machine
        stateMachine?.feedOutput(text)
        state = stateMachine?.state ?? .inactive
    }

    public func terminalSession(_ session: any TerminalSessionManaging, didExitWithCode code: Int32) {
        state = .inactive
        lastEventTime = Date()
    }

    // MARK: - Hook Events

    public func handleHookEvent(_ event: HookEvent) {
        stateMachine?.feedHookEvent(event)
        state = stateMachine?.state ?? state
        lastEventTime = Date()

        // Extract cost from hook
        if case .costDelta(let inputTokens, let outputTokens, let cost) = event,
           let info = agentInfo {
            let entry = CostEntry(
                provider: info.provider,
                model: info.model,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cost: cost,
                sessionId: sessionId
            )
            costReporter.recordCost(entry)
            totalCost = costReporter.totalCost
        }
    }

    // MARK: - Private

    private func tryDetect() {
        hasDetected = true
        let command = terminalSession.sessionId // Would use actual launch command
        if let info = providerRegistry.detect(command: command, initialOutput: outputBuffer) {
            self.agentInfo = info

            // Create appropriate state observer based on provider
            let observer: any AgentStateObservable
            switch info.provider {
            case .claude:
                observer = ClaudeCodeStateObserver()
                stateMachine = AgentStateMachine(stateObserver: observer, hookAuthoritative: true)
            case .codex:
                observer = CodexStateObserver()
                stateMachine = AgentStateMachine(stateObserver: observer)
            case .aider:
                observer = AiderStateObserver()
                stateMachine = AgentStateMachine(stateObserver: observer)
            case .gemini:
                observer = GeminiStateObserver()
                stateMachine = AgentStateMachine(stateObserver: observer)
            case .custom:
                observer = ClaudeCodeStateObserver() // fallback
                stateMachine = AgentStateMachine(stateObserver: observer)
            }

            state = .working
        }
        outputBuffer = ""
    }
}
