// MARK: - Claude Code Provider (Step 3.1)

import Foundation

final class ClaudeCodeDetector: AgentDetectable {

    func detect(command: String, initialOutput: String) -> AgentInfo? {
        let cmd = command.lowercased()
        guard cmd.contains("claude") || cmd.contains("claude-code") else { return nil }

        let model = detectModel(from: initialOutput)
        let sessionId = extractSessionId(from: initialOutput) ?? UUID().uuidString

        return AgentInfo(
            provider: .claude,
            model: model,
            sessionId: sessionId,
            projectPath: nil,
            startTime: Date(),
            launchCommand: command
        )
    }

    private func detectModel(from output: String) -> ModelIdentifier {
        let lower = output.lowercased()

        if lower.contains("opus") {
            return ModelIdentifier(name: "Opus 4", provider: .claude, version: "claude-opus-4-6")
        }
        if lower.contains("sonnet") {
            return ModelIdentifier(name: "Sonnet 4", provider: .claude, version: "claude-sonnet-4-6")
        }
        if lower.contains("haiku") {
            return ModelIdentifier(name: "Haiku 4.5", provider: .claude, version: "claude-haiku-4-5")
        }

        return ModelIdentifier(name: "Claude", provider: .claude, version: nil)
    }

    private func extractSessionId(from output: String) -> String? {
        // Claude Code outputs session ID in initial output
        let pattern = #"session[:\s]+([a-f0-9\-]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let range = Range(match.range(at: 1), in: output) else { return nil }
        return String(output[range])
    }
}

final class ClaudeCodeStateObserver: AgentStateObservable {

    var currentState: AgentState = .inactive
    var onStateChange: ((AgentState, AgentState) -> Void)?

    private var debounceTimer: Timer?
    private var pendingState: AgentState?
    private let debounceInterval: TimeInterval = 0.5

    func processOutput(_ output: String) {
        let lower = output.lowercased()

        let newState: AgentState
        if lower.contains("thinking") || lower.contains("analyzing") || lower.contains("writing") {
            newState = .working
        } else if lower.contains("approve") || lower.contains("permission") || lower.contains("allow") || lower.contains("y/n") {
            newState = .needsInput
        } else if lower.contains("error") || lower.contains("failed") || lower.contains("exception") {
            newState = .error
        } else {
            return // No state change inferred
        }

        scheduleStateChange(newState)
    }

    func processHookEvent(_ event: HookEvent) {
        // Hooks are authoritative — apply immediately, cancel any pending debounce
        debounceTimer?.invalidate()
        debounceTimer = nil

        let newState: AgentState
        switch event {
        case .toolUse, .fileWrite, .fileRead, .commandExec, .subAgentSpawn:
            newState = .working
        case .approval(_, let status):
            switch status {
            case .pending: newState = .needsInput
            case .approved, .rejected: newState = .working
            }
        case .costDelta:
            return // Cost events don't change state
        }

        applyStateChange(newState)
    }

    private func scheduleStateChange(_ state: AgentState) {
        pendingState = state
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            guard let self, let pending = self.pendingState else { return }
            self.applyStateChange(pending)
            self.pendingState = nil
        }
    }

    private func applyStateChange(_ newState: AgentState) {
        guard newState != currentState else { return }
        let oldState = currentState
        currentState = newState
        onStateChange?(oldState, newState)
    }
}

final class ClaudeCodeCostReporter: AgentCostReportable {
    private(set) var totalCost: Decimal = 0
    private(set) var costEntries: [CostEntry] = []

    func recordCost(_ entry: CostEntry) {
        costEntries.append(entry)
        totalCost += entry.cost
    }
}

final class ClaudeCodeController: AgentControllable {
    private let session: any TerminalSessionManaging

    init(session: any TerminalSessionManaging) {
        self.session = session
    }

    func sendInput(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        session.sendInput(data)
    }

    func approve() { sendInput("y\n") }
    func reject() { sendInput("n\n") }
    func terminate() { session.terminate() }
    func restart() {
        session.terminate()
        // Re-launch would be handled by the session manager
    }
}
