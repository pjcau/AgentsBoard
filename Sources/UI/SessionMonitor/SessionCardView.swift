// MARK: - Session Card View (Step 5.2)

import SwiftUI
import AgentsBoardCore

struct SessionCardView: View {
    let viewModel: SessionCardViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            SessionCardHeader(
                name: viewModel.name,
                provider: viewModel.provider,
                modelName: viewModel.modelName,
                state: viewModel.state
            )

            // Real terminal emulator (SwiftTerm) — handles TUI rendering + keyboard input
            if let command = viewModel.launchCommand {
                TerminalEmulatorView(
                    command: command,
                    workingDirectory: viewModel.workDir,
                    onProcessExit: { _ in
                        viewModel.state = .inactive
                    }
                )
                .frame(minHeight: 120)
            } else {
                // Fallback for sessions without a command
                ScrollView(.vertical) {
                    if viewModel.cleanOutput.isEmpty {
                        Text(viewModel.state == .working ? "Waiting for output..." : "No output")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(8)
                    } else {
                        Text(viewModel.cleanOutput)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(8)
                            .textSelection(.enabled)
                    }
                }
                .background(Color.black)
                .frame(minHeight: 80)
            }

            // Footer
            SessionCardFooter(
                cost: viewModel.cost,
                duration: viewModel.duration,
                lastAction: viewModel.lastAction
            )
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(viewModel.borderColor, lineWidth: 2)
        )
        .contextMenu {
            SessionContextMenu(sessionId: viewModel.sessionId)
        }
    }
}

// MARK: - Header

struct SessionCardHeader: View {
    let name: String
    let provider: AgentProvider?
    let modelName: String?
    let state: AgentState

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stateColor)
                .frame(width: 10, height: 10)

            Image(systemName: providerIcon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(name)
                .font(.headline)
                .lineLimit(1)

            Spacer()

            if let model = modelName {
                Text(model)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }

            Text(state.rawValue)
                .font(.caption2)
                .foregroundStyle(stateColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var stateColor: Color {
        switch state {
        case .working: return .green
        case .needsInput: return .yellow
        case .error: return .red
        case .inactive: return .gray
        }
    }

    private var providerIcon: String {
        switch provider {
        case .claude: return "brain.head.profile"
        case .codex: return "chevron.left.forwardslash.chevron.right"
        case .aider: return "wrench.and.screwdriver"
        case .gemini: return "sparkles"
        case .custom, .none: return "terminal"
        }
    }
}

// MARK: - Footer

struct SessionCardFooter: View {
    let cost: String
    let duration: String
    let lastAction: String

    var body: some View {
        HStack {
            Label(cost, systemImage: "dollarsign.circle")
                .font(.caption)
            Spacer()
            Text(duration)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(lastAction)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Context Menu

struct SessionContextMenu: View {
    let sessionId: String

    var body: some View {
        Button("Rename") { /* Step 5.2 */ }
        Button("Kill Session") { /* Step 5.2 */ }
        Button("Restart") { /* Step 5.2 */ }
        Divider()
        Button("Remix to Worktree") { /* Step 14.2 */ }
        Button("Start Recording") { /* Step 15.1 */ }
        Divider()
        Button("Copy Session ID") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(sessionId, forType: .string)
        }
    }
}

// MARK: - View Model

@Observable
final class SessionCardViewModel {
    let sessionId: String
    var name: String
    var provider: AgentProvider?
    var modelName: String?
    var state: AgentState = .inactive
    var cost: String = "$0.00"
    var duration: String = "0m"
    var lastAction: String = ""
    var lastOutput: String = ""
    var launchCommand: String?
    var workDir: String?

    /// Output with ANSI escape codes stripped for display
    var cleanOutput: String {
        Self.stripANSI(lastOutput)
    }

    private weak var session: (any AgentSessionRepresentable)?
    private var refreshTimer: Timer?

    var borderColor: Color {
        switch state {
        case .working: return .green.opacity(0.6)
        case .needsInput: return .yellow.opacity(0.8)
        case .error: return .red.opacity(0.7)
        case .inactive: return .gray.opacity(0.3)
        }
    }

    init(session: any AgentSessionRepresentable) {
        self.session = session
        self.sessionId = session.sessionId
        self.name = session.agentInfo?.provider.rawValue.capitalized ?? "Session"
        self.provider = session.agentInfo?.provider
        self.modelName = session.agentInfo?.model.name
        self.state = session.state
        self.cost = Self.formatCost(session.totalCost)
        self.duration = Self.formatDuration(since: session.startTime)
        self.lastOutput = session.outputText
        self.launchCommand = session.launchCommand
        self.workDir = session.projectPath
        startRefreshing()
    }

    init(id: String = UUID().uuidString, name: String = "Session") {
        self.sessionId = id
        self.name = name
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func sendInput(_ text: String) {
        session?.sendInput(text)
    }

    private func startRefreshing() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func refresh() {
        guard let session else {
            refreshTimer?.invalidate()
            return
        }
        state = session.state
        cost = Self.formatCost(session.totalCost)
        duration = Self.formatDuration(since: session.startTime)
        lastOutput = session.outputText
    }

    /// Strips ANSI/VT100/xterm escape sequences from terminal output.
    /// Uses a character-by-character state machine for reliability.
    private static func stripANSI(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)
        var chars = text.unicodeScalars.makeIterator()

        while let c = chars.next() {
            if c == "\u{1b}" {
                // ESC — consume the entire escape sequence
                guard let next = chars.next() else { break }
                switch next {
                case "[":
                    // CSI: ESC [ (params) (intermediates) final_byte
                    // Params: 0x30-0x3F, Intermediates: 0x20-0x2F, Final: 0x40-0x7E
                    var ch = chars.next()
                    while let c2 = ch, c2.value >= 0x20 && c2.value <= 0x3F { ch = chars.next() }
                    // intermediates
                    while let c2 = ch, c2.value >= 0x20 && c2.value <= 0x2F { ch = chars.next() }
                    // final byte consumed (0x40-0x7E), or we ran out
                    continue
                case "]":
                    // OSC: ESC ] ... (BEL | ESC \)
                    while let c2 = chars.next() {
                        if c2 == "\u{07}" { break }  // BEL
                        if c2 == "\u{1b}" { let _ = chars.next(); break }  // ST = ESC backslash
                    }
                    continue
                case "P":
                    // DCS: ESC P ... ST
                    while let c2 = chars.next() {
                        if c2 == "\u{1b}" { let _ = chars.next(); break }
                    }
                    continue
                case "(", ")", "*", "+":
                    // Character set designation — skip one more char
                    let _ = chars.next()
                    continue
                default:
                    // Single-char escape (ESC =, ESC >, ESC c, etc.)
                    continue
                }
            } else if c.value < 0x20 {
                // Control characters — keep only \n, \r, \t
                if c == "\n" || c == "\r" || c == "\t" {
                    result.append(Character(c))
                }
                // Drop all others (BEL, BS, SI, SO, etc.)
                continue
            } else {
                result.append(Character(c))
            }
        }

        // Clean up excessive blank lines
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func formatCost(_ cost: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: cost as NSDecimalNumber) ?? "$0.00"
    }

    private static func formatDuration(since date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}
