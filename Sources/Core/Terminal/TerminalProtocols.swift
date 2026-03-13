// MARK: - Terminal Protocols

import Foundation

/// Manages a terminal session lifecycle: create, resize, send input, destroy.
public protocol TerminalSessionManaging: AnyObject {
    var sessionId: String { get }
    var isRunning: Bool { get }
    var terminalSize: TerminalSize { get }

    func launch(command: String, workingDirectory: String?, environment: [String: String]?) throws
    func sendInput(_ data: Data)
    func resize(columns: Int, rows: Int)
    func terminate()

    var dataDelegate: TerminalDataReceiving? { get set }
}

/// Receives data output from a terminal session.
public protocol TerminalDataReceiving: AnyObject {
    func terminalSession(_ session: any TerminalSessionManaging, didReceiveData data: Data)
    func terminalSession(_ session: any TerminalSessionManaging, didExitWithCode code: Int32)
}

/// Terminal dimensions.
public struct TerminalSize: Equatable, Sendable {
    public let columns: Int
    public let rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }

    public static let `default` = TerminalSize(columns: 80, rows: 24)
}
