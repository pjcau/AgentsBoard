// MARK: - Gemini Provider (Step 3.1)

import Foundation

final class GeminiDetector: AgentDetectable {

    func detect(command: String, initialOutput: String) -> AgentInfo? {
        let cmd = command.lowercased()
        guard cmd.contains("gemini") else { return nil }

        let model = detectModel(from: initialOutput)

        return AgentInfo(
            provider: .gemini,
            model: model,
            sessionId: UUID().uuidString,
            projectPath: nil,
            startTime: Date(),
            launchCommand: command
        )
    }

    private func detectModel(from output: String) -> ModelIdentifier {
        let lower = output.lowercased()
        if lower.contains("2.5 pro") { return ModelIdentifier(name: "Gemini 2.5 Pro", provider: .gemini, version: "gemini-2.5-pro") }
        if lower.contains("2.5 flash") { return ModelIdentifier(name: "Gemini 2.5 Flash", provider: .gemini, version: "gemini-2.5-flash") }
        return ModelIdentifier(name: "Gemini", provider: .gemini, version: nil)
    }
}

final class GeminiStateObserver: AgentStateObservable {
    var currentState: AgentState = .inactive
    var onStateChange: ((AgentState, AgentState) -> Void)?

    func processOutput(_ output: String) {
        let lower = output.lowercased()
        let newState: AgentState
        if lower.contains("thinking") || lower.contains("generating") {
            newState = .working
        } else if lower.contains("confirm") || lower.contains("proceed") {
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

    func processHookEvent(_ event: HookEvent) {}
}
