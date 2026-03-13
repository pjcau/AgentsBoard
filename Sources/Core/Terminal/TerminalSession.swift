// MARK: - Terminal Session (Step 2.1)
// Implements TerminalSessionManaging. Combines PTY + VT parsing + state.

import Foundation
import Observation

@Observable
public final class TerminalSession: TerminalSessionManaging {

    // MARK: - Properties

    public let sessionId: String
    public private(set) var isRunning: Bool = false
    public private(set) var terminalSize: TerminalSize = .default

    public weak var dataDelegate: TerminalDataReceiving?

    private var process: PTYProcess?
    private var launchCommand: String?
    private var workingDirectory: String?
    private var environment: [String: String]?

    // MARK: - Init

    public init(sessionId: String = UUID().uuidString) {
        self.sessionId = sessionId
    }

    // MARK: - TerminalSessionManaging

    public func launch(
        command: String,
        workingDirectory: String? = nil,
        environment: [String: String]? = nil
    ) throws {
        guard !isRunning else { return }

        self.launchCommand = command
        self.workingDirectory = workingDirectory
        self.environment = environment

        let pty = try PTYProcess(
            command: command,
            workingDirectory: workingDirectory,
            environment: environment,
            size: terminalSize
        )
        self.process = pty
        self.isRunning = true
    }

    public func sendInput(_ data: Data) {
        process?.write(data)
    }

    public func resize(columns: Int, rows: Int) {
        terminalSize = TerminalSize(columns: columns, rows: rows)
        process?.resize(columns: columns, rows: rows)
    }

    public func terminate() {
        process?.terminate()
        isRunning = false
    }

    // MARK: - Internal

    /// Access the underlying PTY for multiplexer registration.
    public var ptyProcess: PTYProcess? { process }

    /// Called when the process exits.
    func markExited() {
        isRunning = false
    }
}
