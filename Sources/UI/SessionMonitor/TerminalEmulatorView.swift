// MARK: - Terminal Emulator View (SwiftTerm wrapper)
//
// Wraps SwiftTerm's LocalProcessTerminalView in an NSViewRepresentable
// for use in SwiftUI. Provides a real terminal emulator that renders
// TUI apps (Claude Code, etc.) correctly with colors, cursor, and input.

import SwiftUI
import SwiftTerm
import AgentsBoardCore

// MARK: - Font Size Constants

/// Shared constants for terminal font size, used by both the view and the menu commands.
public enum TerminalFontSize {
    public static let defaultSize: Double = 13
    public static let minimum: Double = 8
    public static let maximum: Double = 28
    public static let step: Double = 1
    public static let appStorageKey = "terminalFontSize"
}

/// SwiftUI wrapper for SwiftTerm's LocalProcessTerminalView.
/// Launches a process in a PTY and renders full terminal output.
struct TerminalEmulatorView: NSViewRepresentable {
    let command: String
    let workingDirectory: String?
    let onProcessExit: ((Int32?) -> Void)?

    @AppStorage(TerminalFontSize.appStorageKey) private var fontSize: Double = TerminalFontSize.defaultSize

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let termView = LocalProcessTerminalView(frame: .zero)
        termView.processDelegate = context.coordinator

        // Configure terminal appearance
        termView.nativeBackgroundColor = .black
        termView.nativeForegroundColor = .green

        // Apply the persisted font size on creation
        if let monoFont = NSFont.userFixedPitchFont(ofSize: fontSize) {
            termView.font = monoFont
        }

        // Use a login shell so it loads the user's full PATH (~/.zshrc, ~/.zprofile, etc.)
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

        // Inherit the current process's full environment (includes PATH with npm, homebrew, etc.)
        var env: [String] = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
        // Override TERM for proper rendering
        env.removeAll { $0.hasPrefix("TERM=") }
        env.append("TERM=xterm-256color")
        if !env.contains(where: { $0.hasPrefix("LANG=") }) {
            env.append("LANG=en_US.UTF-8")
        }

        // Use login shell (-l) with -c to run the command, so ~/.zshrc is sourced
        termView.startProcess(
            executable: shell,
            args: ["-l", "-c", command],
            environment: env,
            currentDirectory: workingDirectory
        )

        return termView
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        // Re-apply font when fontSize AppStorage value changes
        guard let monoFont = NSFont.userFixedPitchFont(ofSize: fontSize),
              nsView.font.pointSize != monoFont.pointSize
        else { return }
        nsView.font = monoFont
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onProcessExit: onProcessExit)
    }

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        let onProcessExit: ((Int32?) -> Void)?

        init(onProcessExit: ((Int32?) -> Void)?) {
            self.onProcessExit = onProcessExit
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            DispatchQueue.main.async { [weak self] in
                self?.onProcessExit?(exitCode)
            }
        }
    }
}
