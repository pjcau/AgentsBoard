// MARK: - PTY Process (Step 2.1)
// Wraps a single child process with a pseudo-terminal.

import Foundation

public final class PTYProcess {

    // MARK: - Properties

    public let fileDescriptor: Int32
    public let pid: pid_t
    private(set) var isRunning: Bool = true
    private(set) var isSuspended: Bool = false

    // MARK: - Init

    /// Creates a new PTY process with the given command.
    /// - Parameters:
    ///   - command: Shell command to execute (e.g., "claude", "/bin/zsh")
    ///   - workingDirectory: Working directory for the child process
    ///   - environment: Additional environment variables
    ///   - size: Initial terminal size
    init(
        command: String,
        workingDirectory: String? = nil,
        environment: [String: String]? = nil,
        size: TerminalSize = .default
    ) throws {
        var winSize = winsize(
            ws_row: UInt16(size.rows),
            ws_col: UInt16(size.columns),
            ws_xpixel: 0,
            ws_ypixel: 0
        )

        var masterFD: Int32 = -1
        let childPid = forkpty(&masterFD, nil, nil, &winSize)

        guard childPid >= 0 else {
            throw PTYError.forkFailed(errno)
        }

        if childPid == 0 {
            // Child process
            if let workDir = workingDirectory {
                chdir(workDir)
            }

            // Set environment
            if let env = environment {
                for (key, value) in env {
                    setenv(key, value, 1)
                }
            }

            // Set TERM
            setenv("TERM", "xterm-256color", 1)

            // Execute command via shell
            let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
            let args = [shell, "-c", command]
            let cArgs = args.map { strdup($0) } + [nil]
            execv(shell, cArgs)

            // If exec fails
            _exit(127)
        }

        // Parent process
        self.fileDescriptor = masterFD
        self.pid = childPid

        // Set non-blocking
        let flags = fcntl(masterFD, F_GETFL)
        fcntl(masterFD, F_SETFL, flags | O_NONBLOCK)
    }

    deinit {
        cleanup()
    }

    // MARK: - Operations

    func write(_ data: Data) {
        data.withUnsafeBytes { buffer in
            guard let ptr = buffer.baseAddress else { return }
            Foundation.write(fileDescriptor, ptr, buffer.count)
        }
    }

    func resize(columns: Int, rows: Int) {
        var winSize = winsize(
            ws_row: UInt16(rows),
            ws_col: UInt16(columns),
            ws_xpixel: 0,
            ws_ypixel: 0
        )
        ioctl(fileDescriptor, TIOCSWINSZ, &winSize)
    }

    /// Suspends the process (SIGSTOP). The process state is preserved in memory
    /// but it consumes zero CPU. Resume with `resume()`.
    func suspend() {
        guard isRunning, !isSuspended else { return }
        kill(pid, SIGSTOP)
        isSuspended = true
    }

    /// Resumes a previously suspended process (SIGCONT).
    func resume() {
        guard isRunning, isSuspended else { return }
        kill(pid, SIGCONT)
        isSuspended = false
    }

    func terminate() {
        guard isRunning else { return }
        // Resume first if suspended, otherwise SIGTERM may not be delivered
        if isSuspended {
            kill(pid, SIGCONT)
            isSuspended = false
        }
        kill(pid, SIGTERM)

        // Give process time to exit gracefully, then force kill
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, self.isRunning else { return }
            kill(self.pid, SIGKILL)
        }
    }

    func waitForExit() -> Int32 {
        var status: Int32 = 0
        waitpid(pid, &status, 0)
        isRunning = false
        return (status >> 8) & 0xFF
    }

    // MARK: - Private

    private func cleanup() {
        if isRunning {
            if isSuspended { kill(pid, SIGCONT) }
            kill(pid, SIGTERM)
        }
        close(fileDescriptor)
        isRunning = false
        isSuspended = false
    }
}

// MARK: - PTY Errors

enum PTYError: Error, LocalizedError {
    case forkFailed(Int32)

    var errorDescription: String? {
        switch self {
        case .forkFailed(let errno):
            return "forkpty failed with errno \(errno): \(String(cString: strerror(errno)))"
        }
    }
}
