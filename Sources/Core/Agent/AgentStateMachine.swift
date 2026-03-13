// MARK: - Agent State Machine (Step 3.2)
// Tracks agent state with debouncing and hook authority.

import Foundation
import Observation

@Observable
public final class AgentStateMachine {

    // MARK: - Properties

    public private(set) var state: AgentState = .inactive
    public private(set) var model: ModelIdentifier?
    public private(set) var lastStateChange: Date = Date()

    private let stateObserver: any AgentStateObservable
    private let hookAuthoritative: Bool

    // MARK: - Init

    public init(stateObserver: any AgentStateObservable, hookAuthoritative: Bool = false) {
        self.stateObserver = stateObserver
        self.hookAuthoritative = hookAuthoritative

        stateObserver.onStateChange = { [weak self] oldState, newState in
            self?.state = newState
            self?.lastStateChange = Date()
        }
    }

    // MARK: - Feed

    public func feedOutput(_ output: String) {
        stateObserver.processOutput(output)
    }

    public func feedHookEvent(_ event: HookEvent) {
        stateObserver.processHookEvent(event)
    }
}
