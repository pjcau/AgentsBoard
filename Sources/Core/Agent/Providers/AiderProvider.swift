// MARK: - Aider Provider (Step 3.1)

import Foundation

final class AiderDetector: AgentDetectable {

    func detect(command: String, initialOutput: String) -> AgentInfo? {
        let cmd = command.lowercased()
        guard cmd.contains("aider") else { return nil }

        let model = detectModel(from: initialOutput)

        return AgentInfo(
            provider: .aider,
            model: model,
            sessionId: UUID().uuidString,
            projectPath: nil,
            startTime: Date(),
            launchCommand: command
        )
    }

    private func detectModel(from output: String) -> ModelIdentifier {
        let lower = output.lowercased()
        if lower.contains("opus") { return ModelIdentifier(name: "Opus", provider: .aider, version: nil) }
        if lower.contains("sonnet") { return ModelIdentifier(name: "Sonnet", provider: .aider, version: nil) }
        if lower.contains("gpt-4") { return ModelIdentifier(name: "GPT-4", provider: .aider, version: nil) }
        if lower.contains("deepseek") { return ModelIdentifier(name: "DeepSeek", provider: .aider, version: nil) }
        return ModelIdentifier(name: "Aider", provider: .aider, version: nil)
    }
}

final class AiderStateObserver: AgentStateObservable {
    var currentState: AgentState = .inactive
    var onStateChange: ((AgentState, AgentState) -> Void)?

    func processOutput(_ output: String) {
        let lower = output.lowercased()
        let newState: AgentState
        if lower.contains("thinking") || lower.contains("editing") || lower.contains("applying") {
            newState = .working
        } else if lower.contains(">") && lower.hasSuffix("> ") {
            newState = .needsInput
        } else if lower.contains("error") || lower.contains("traceback") {
            newState = .error
        } else {
            return
        }
        guard newState != currentState else { return }
        let old = currentState
        currentState = newState
        onStateChange?(old, newState)
    }

    func processHookEvent(_ event: HookEvent) {}
}
