// MARK: - Protocol Conformance & Agent Tests

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - Mock Implementations

final class MockAgentDetector: AgentDetectable {
    var detectResult: AgentInfo?
    func detect(command: String, initialOutput: String) -> AgentInfo? { detectResult }
}

final class MockAgentStateObserver: AgentStateObservable {
    var currentState: AgentState = .inactive
    var onStateChange: ((AgentState, AgentState) -> Void)?
    func processOutput(_ output: String) {}
    func processHookEvent(_ event: HookEvent) {}
}

final class MockAgentCostReporter: AgentCostReportable {
    var totalCost: Decimal = 0
    var costEntries: [CostEntry] = []
    func recordCost(_ entry: CostEntry) {
        costEntries.append(entry)
        totalCost += entry.cost
    }
}

final class MockAgentController: AgentControllable {
    var lastInput: String?
    var approvedCount = 0
    var rejectedCount = 0
    var terminatedCount = 0
    var restartedCount = 0
    func sendInput(_ text: String) { lastInput = text }
    func approve() { approvedCount += 1 }
    func reject() { rejectedCount += 1 }
    func terminate() { terminatedCount += 1 }
    func restart() { restartedCount += 1 }
}

// MARK: - Agent Provider Tests

@Suite("AgentProvider")
struct AgentProviderTests {
    @Test func allCasesCount() {
        #expect(AgentProvider.allCases.count == 5)
    }

    @Test func rawValues() {
        #expect(AgentProvider.claude.rawValue == "claude")
        #expect(AgentProvider.codex.rawValue == "codex")
        #expect(AgentProvider.aider.rawValue == "aider")
        #expect(AgentProvider.gemini.rawValue == "gemini")
        #expect(AgentProvider.custom.rawValue == "custom")
    }
}

// MARK: - Agent State Tests

@Suite("AgentState")
struct AgentStateTests {
    @Test func allStates() {
        #expect(AgentState.working.rawValue == "working")
        #expect(AgentState.needsInput.rawValue == "needsInput")
        #expect(AgentState.error.rawValue == "error")
        #expect(AgentState.inactive.rawValue == "inactive")
    }
}

// MARK: - Model Identifier Tests

@Suite("ModelIdentifier")
struct ModelIdentifierTests {
    @Test func creation() {
        let model = ModelIdentifier(name: "Opus", provider: .claude, version: "claude-opus-4-6")
        #expect(model.name == "Opus")
        #expect(model.provider == .claude)
        #expect(model.version == "claude-opus-4-6")
    }

    @Test func withoutVersion() {
        let model = ModelIdentifier(name: "GPT-4", provider: .codex, version: nil)
        #expect(model.version == nil)
    }
}

// MARK: - CostEntry Tests

@Suite("CostEntry")
struct CostEntryTests {
    @Test func creation() {
        let entry = CostEntry(
            provider: .claude,
            model: makeModel(name: "Sonnet"),
            inputTokens: 1000, outputTokens: 500,
            cost: 0.05, sessionId: "s1", taskId: "t1"
        )
        #expect(entry.provider == .claude)
        #expect(entry.inputTokens == 1000)
        #expect(entry.outputTokens == 500)
        #expect(entry.cost == 0.05)
        #expect(entry.sessionId == "s1")
        #expect(entry.taskId == "t1")
    }

    @Test func uniqueIds() {
        let e1 = makeCostEntry()
        let e2 = makeCostEntry()
        #expect(e1.id != e2.id)
    }
}

// MARK: - Agent Controller Tests

@Suite("AgentControllable")
struct AgentControllableTests {
    @Test func sendInput() {
        let controller = MockAgentController()
        controller.sendInput("hello world")
        #expect(controller.lastInput == "hello world")
    }

    @Test func approve() {
        let controller = MockAgentController()
        controller.approve()
        controller.approve()
        #expect(controller.approvedCount == 2)
    }

    @Test func reject() {
        let controller = MockAgentController()
        controller.reject()
        #expect(controller.rejectedCount == 1)
    }

    @Test func terminate() {
        let controller = MockAgentController()
        controller.terminate()
        #expect(controller.terminatedCount == 1)
    }

    @Test func restart() {
        let controller = MockAgentController()
        controller.restart()
        #expect(controller.restartedCount == 1)
    }
}

// MARK: - Cost Reporter Tests

@Suite("AgentCostReportable")
struct AgentCostReportableTests {
    @Test func recordMultipleCosts() {
        let reporter = MockAgentCostReporter()
        reporter.recordCost(makeCostEntry(cost: 0.01))
        reporter.recordCost(makeCostEntry(cost: 0.02))
        #expect(reporter.totalCost == 0.03)
        #expect(reporter.costEntries.count == 2)
    }
}

// MARK: - Provider Registry Tests

@Suite("ProviderRegistry")
struct ProviderRegistryTests {
    @Test func registerAndDetect() {
        let registry = ProviderRegistry()
        let detector = MockAgentDetector()
        detector.detectResult = AgentInfo(
            provider: .claude, model: makeModel(),
            sessionId: "s1", projectPath: "/test",
            startTime: Date(), launchCommand: "claude"
        )
        registry.register(detector)
        let result = registry.detect(command: "claude", initialOutput: "")
        #expect(result?.provider == .claude)
    }

    @Test func detectReturnsNilWhenNoMatch() {
        let registry = ProviderRegistry()
        let detector = MockAgentDetector()
        detector.detectResult = nil
        registry.register(detector)
        #expect(registry.detect(command: "unknown", initialOutput: "") == nil)
    }
}

// MARK: - Agent State Machine Tests

@Suite("AgentStateMachine")
struct AgentStateMachineTests {
    @Test func initialState() {
        let observer = MockAgentStateObserver()
        let machine = AgentStateMachine(stateObserver: observer)
        #expect(machine.state == .inactive)
    }
}
