// MARK: - Session Card View (Step 5.2)

import SwiftUI
import AgentsBoardCore

// MARK: - Session Tab

enum SessionTab: String, CaseIterable {
    case terminal = "Terminal"
    case files = "Files"

    var icon: String {
        switch self {
        case .terminal: return "terminal"
        case .files: return "folder"
        }
    }
}

struct SessionCardView: View {
    let viewModel: SessionCardViewModel
    @State private var selectedTab: SessionTab = .terminal
    @State private var terminalId = UUID()
    @State private var fileVM = FileExplorerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            SessionCardHeader(
                name: viewModel.name,
                provider: viewModel.provider,
                modelName: viewModel.modelName,
                state: viewModel.state
            )

            // Tab content
            Group {
                switch selectedTab {
                case .terminal:
                    terminalContent
                case .files:
                    filesContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab bar
            SessionTabBar(
                selectedTab: $selectedTab,
                onRefreshTerminal: {
                    terminalId = UUID()
                },
                onOpenDiff: {
                    DiffWindowPresenter.shared.present(workDir: viewModel.workDir, sessionName: viewModel.name)
                }
            )

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
            SessionContextMenu(
                sessionId: viewModel.sessionId,
                sessionName: viewModel.name,
                projectPath: viewModel.workDir,
                onRemix: viewModel.onRemix,
                onRename: viewModel.onRename,
                onKill: viewModel.onKill,
                onRestart: viewModel.onRestart,
                onToggleRecording: viewModel.onToggleRecording,
                isRecording: viewModel.isRecording
            )
        }
        .onAppear {
            if let dir = viewModel.workDir, !dir.isEmpty {
                fileVM.loadDirectory(at: dir)
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var terminalContent: some View {
        if let command = viewModel.launchCommand {
            TerminalEmulatorView(
                command: command,
                workingDirectory: viewModel.workDir,
                onProcessExit: { _ in
                    viewModel.state = .inactive
                }
            )
            .id(terminalId)
            .frame(minHeight: 120)
        } else {
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
    }

    @ViewBuilder
    private var filesContent: some View {
        if viewModel.workDir != nil, !viewModel.workDir!.isEmpty {
            FileExplorerView(viewModel: fileVM)
        } else {
            Text("No working directory set")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Session Tab Bar

struct SessionTabBar: View {
    @Binding var selectedTab: SessionTab
    let onRefreshTerminal: () -> Void
    let onOpenDiff: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SessionTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.caption)
                        Text(tab.rawValue)
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(selectedTab == tab ? .primary : .secondary)
            }

            // Diff button — opens separate window
            Button {
                onOpenDiff()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.caption)
                    Text("Diff")
                        .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)

            Spacer()

            if selectedTab == .terminal {
                Button {
                    onRefreshTerminal()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Restart terminal")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Diff Window Presenter (opens diff in a separate modal window)

final class DiffWindowPresenter {
    static let shared = DiffWindowPresenter()
    private var window: NSWindow?

    func present(workDir: String?, sessionName: String) {
        guard let workDir, !workDir.isEmpty else { return }

        // If already showing, bring to front
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let diffView = DiffWindowContentView(workDir: workDir, sessionName: sessionName, onClose: { [weak self] in
            self?.dismiss()
        })

        let hostingView = NSHostingView(rootView: diffView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Diff — \(sessionName)"
        window.contentView = hostingView
        window.minSize = NSSize(width: 500, height: 350)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    func dismiss() {
        window?.close()
        window = nil
    }
}

// MARK: - Diff Window Content

private struct DiffWindowContentView: View {
    let workDir: String
    let sessionName: String
    let onClose: () -> Void

    @State private var diffVM = DiffReviewViewModel()
    @State private var loading = true

    var body: some View {
        VStack(spacing: 0) {
            if loading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading diff...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if diffVM.hunks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text("No changes detected")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(workDir)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                DiffReviewView(viewModel: diffVM)
            }
        }
        .onAppear { loadDiff() }
    }

    private func loadDiff() {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["diff", "--no-color"]
            process.currentDirectoryURL = URL(fileURLWithPath: workDir)
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                DispatchQueue.main.async {
                    let parser = DiffParser()
                    let hunks = parser.parse(unifiedDiff: output)
                    diffVM.fileName = workDir.components(separatedBy: "/").last ?? "Workspace"
                    diffVM.hunks = hunks
                    loading = false
                }
            } catch {
                DispatchQueue.main.async { loading = false }
            }
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
    let sessionName: String
    let projectPath: String?
    var onRemix: (() -> Void)?
    var onRename: ((String) -> Void)?
    var onKill: (() -> Void)?
    var onRestart: (() -> Void)?
    var onToggleRecording: (() -> Void)?
    var isRecording: Bool = false

    var body: some View {
        Button("Rename...") {
            onRename?(sessionName)
        }
        Button("Kill Session", role: .destructive) {
            onKill?()
        }
        Button("Restart") {
            onRestart?()
        }
        Divider()
        if projectPath != nil, !(projectPath?.isEmpty ?? true) {
            Button("Remix to Worktree") { onRemix?() }
        }
        Button(isRecording ? "Stop Recording" : "Start Recording") {
            onToggleRecording?()
        }
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
    var onRemix: (() -> Void)?
    var onKill: (() -> Void)?
    var onRestart: (() -> Void)?
    var onRename: ((String) -> Void)?
    var onToggleRecording: (() -> Void)?
    var isRecording: Bool = false

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
        self.name = session.sessionName
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
