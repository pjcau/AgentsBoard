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
    private var readThread: Thread?

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

        // Start read loop for platforms without SwiftTerm (Linux)
        #if !canImport(Darwin) || true
        startReadLoop(fd: pty.fileDescriptor)
        #endif
    }

    /// Reads PTY output in a background thread using blocking POSIX read().
    private func startReadLoop(fd: Int32) {
        let session = self
        DispatchQueue.global(qos: .userInteractive).async {
            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }

            while session.isRunning {
                #if canImport(Glibc)
                let n = Glibc.read(fd, buffer, bufferSize)
                #else
                let n = Foundation.read(fd, buffer, bufferSize)
                #endif
                if n > 0 {
                    let data = Data(bytes: buffer, count: n)
                    let delegate = session.dataDelegate
                    DispatchQueue.main.async {
                        delegate?.terminalSession(session, didReceiveData: data)
                    }
                } else {
                    // EOF or error — process exited
                    let exitCode = session.process?.waitForExit() ?? 0
                    let delegate = session.dataDelegate
                    DispatchQueue.main.async {
                        session.markExited()
                        delegate?.terminalSession(session, didExitWithCode: exitCode)
                    }
                    break
                }
            }
        }
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
