// MARK: - Session Card View (Step 5.2)

import SwiftUI
import AgentsBoardCore

struct SessionCardView: View {
    let viewModel: SessionCardViewModel
    @State private var inputText: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            SessionCardHeader(
                name: viewModel.name,
                provider: viewModel.provider,
                modelName: viewModel.modelName,
                state: viewModel.state
            )

            // Terminal output area
            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical]) {
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
                            .id("output-bottom")
                    }
                }
                .onChange(of: viewModel.cleanOutput) {
                    proxy.scrollTo("output-bottom", anchor: .bottom)
                }
            }
            .background(Color.black)
            .frame(minHeight: 80)

            // Input bar (send commands to the PTY)
            if viewModel.state == .working || viewModel.state == .needsInput {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.green)
                    TextField("Type command...", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.green)
                        .focused($inputFocused)
                        .onSubmit {
                            guard !inputText.isEmpty else { return }
                            viewModel.sendInput(inputText + "\n")
                            inputText = ""
                        }
                    Button {
                        guard !inputText.isEmpty else { return }
                        viewModel.sendInput(inputText + "\n")
                        inputText = ""
                    } label: {
                        Image(systemName: "return")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .disabled(inputText.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.8))
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

    /// Strips ANSI/VT100 escape sequences from terminal output
    private static func stripANSI(_ text: String) -> String {
        let esc = "\u{1b}"  // ESC character
        let bel = "\u{07}"  // BEL character
        let si  = "\u{0f}"  // SI
        let so  = "\u{0e}"  // SO

        // Build regex patterns using the escape character
        let patterns = [
            "\(esc)\\[[0-9;]*[A-Za-z]",              // CSI sequences (colors, cursor, etc.)
            "\(esc)\\][^\(bel)\(esc)]*(?:\(bel)|\(esc)\\\\)",  // OSC sequences
            "\(esc)\\([A-Z]",                          // Character set selection
            "\(esc)[>=<]",                             // Keypad/ANSI mode
            "\(esc)\\[\\?[0-9;]*[hl]",                // DEC private modes
            "[\(si)\(so)]",                            // SI/SO
        ]
        let combined = patterns.joined(separator: "|")
        guard let regex = try? NSRegularExpression(pattern: combined) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
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
