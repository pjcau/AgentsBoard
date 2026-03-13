// MARK: - Provider Registry (Step 3.1)
// OCP: Register new providers without modifying existing code.

import Foundation

public final class ProviderRegistry {

    // MARK: - Properties

    private var detectors: [any AgentDetectable] = []

    public init() {}

    // MARK: - Registration (OCP)

    public func register(_ detector: any AgentDetectable) {
        detectors.append(detector)
    }

    // MARK: - Detection (Chain of Responsibility)

    public func detect(command: String, initialOutput: String) -> AgentInfo? {
        for detector in detectors {
            if let info = detector.detect(command: command, initialOutput: initialOutput) {
                return info
            }
        }
        return nil
    }
}
