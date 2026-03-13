// MARK: - Codex Provider (Step 3.1)

import Foundation

final class CodexDetector: AgentDetectable {

    func detect(command: String, initialOutput: String) -> AgentInfo? {
        let cmd = command.lowercased()
        guard cmd.contains("codex") else { return nil }

        let model = detectModel(from: initialOutput)

        return AgentInfo(
            provider: .codex,
            model: model,
            sessionId: UUID().uuidString,
            projectPath: nil,
            startTime: Date(),
            launchCommand: command
        )
    }

    private func detectModel(from output: String) -> ModelIdentifier {
        let lower = output.lowercased()
        if lower.contains("gpt-4") || lower.contains("o3") {
            return ModelIdentifier(name: "GPT-4", provider: .codex, version: "gpt-4")
        }
        if lower.contains("o4-mini") {
            return ModelIdentifier(name: "o4-mini", provider: .codex, version: "o4-mini")
        }
        return ModelIdentifier(name: "Codex", provider: .codex, version: nil)
    }
}

final class CodexStateObserver: AgentStateObservable {
    var currentState: AgentState = .inactive
    var onStateChange: ((AgentState, AgentState) -> Void)?

    func processOutput(_ output: String) {
        let lower = output.lowercased()
        let newState: AgentState
        if lower.contains("running") || lower.contains("thinking") {
            newState = .working
        } else if lower.contains("confirm") || lower.contains("approve") {
            newState = .needsInput
        } else if lower.contains("error") || lower.contains("failed") {
            newState = .error
        } else {
            return
        }
        guard newState != currentState else { return }
        let old = currentState
        currentState = newState
        onStateChange?(old, newState)
    }

    func processHookEvent(_ event: HookEvent) {
        // Codex doesn't support hooks — no-op
    }
}
