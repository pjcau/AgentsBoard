// MARK: - Agent Protocols (ISP: four separate protocols)

import Foundation

/// Detects whether a running process is an AI agent and identifies its provider/model.
public protocol AgentDetectable {
    func detect(command: String, initialOutput: String) -> AgentInfo?
}

/// Observes and emits real-time state changes for a detected agent session.
public protocol AgentStateObservable: AnyObject {
    var currentState: AgentState { get }
    func processOutput(_ output: String)
    func processHookEvent(_ event: HookEvent)
    var onStateChange: ((AgentState, AgentState) -> Void)? { get set }
}

/// Reports cost data for an agent session.
public protocol AgentCostReportable {
    var totalCost: Decimal { get }
    var costEntries: [CostEntry] { get }
    func recordCost(_ entry: CostEntry)
}

/// Allows sending input/commands to an agent session.
public protocol AgentControllable {
    func sendInput(_ text: String)
    func approve()
    func reject()
    func terminate()
    func restart()
}
