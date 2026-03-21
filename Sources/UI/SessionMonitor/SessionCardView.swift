// MARK: - Session Card View (Step 5.2)

import SwiftUI
import AgentsBoardCore

// MARK: - Session Tab

enum SessionTab: String, CaseIterable {
    case terminal
    case activity
    case info
    case files

    var localizedTitle: String {
        switch self {
        case .terminal: return L10n.Tab.terminal
        case .activity: return L10n.Tab.activity
        case .info: return L10n.Tab.info
        case .files: return L10n.Tab.files
        }
    }

    var icon: String {
        switch self {
        case .terminal: return "terminal"
        case .activity: return "clock"
        case .info: return "info.circle"
        case .files: return "folder"
        }
    }
}

struct SessionCardView: View {
    let viewModel: SessionCardViewModel
    var isFocused: Bool = false
    @State private var selectedTab: SessionTab = .terminal
    @State private var terminalId = UUID()
    @State private var fileVM = FileExplorerViewModel()
    @State private var showingEdit = false
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            SessionCardHeader(
                name: viewModel.name,
                provider: viewModel.provider,
                modelName: viewModel.modelName,
                state: viewModel.state,
                onEdit: { showingEdit = true }
            )

            // Tab content — terminal stays alive (hidden via offset) to preserve PTY process.
            // Using offset instead of opacity(0) prevents Metal/CALayer from stalling
            // draw calls on hidden layers, which caused terminal content loss on tab switch.
            ZStack {
                // Terminal is always in the view tree to keep PTY alive.
                // When not selected, we move it far offscreen (not opacity 0) so Metal
                // keeps drawing and the CALayer stays active.
                terminalContent
                    .offset(y: selectedTab == .terminal ? 0 : 100_000)
                    .allowsHitTesting(selectedTab == .terminal)

                // Overlay tabs are only created when selected
                if selectedTab == .activity {
                    SessionActivityContent(viewModel: viewModel)
                } else if selectedTab == .info {
                    SessionInfoContent(viewModel: viewModel)
                } else if selectedTab == .files {
                    filesContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

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

            // Resources panel (collapsible, like AgentHub)
            if !viewModel.detectedLinks.isEmpty {
                ResourceLinksPanel(links: viewModel.detectedLinks, provider: viewModel.provider)
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
            SessionContextMenu(
                sessionId: viewModel.sessionId,
                sessionName: viewModel.name,
                projectPath: viewModel.workDir,
                onRemix: viewModel.onRemix,
                onEdit: { showingEdit = true },
                onRename: { _ in showingEdit = true },
                onKill: viewModel.onKill,
                onRestart: viewModel.onRestart,
                onToggleRecording: viewModel.onToggleRecording,
                isRecording: viewModel.isRecording,
                onArchive: viewModel.onArchive,
                onDelete: viewModel.onDelete
            )
        }
        .sheet(isPresented: $showingEdit) {
            SessionEditView(
                isPresented: $showingEdit,
                name: viewModel.name,
                command: viewModel.launchCommand ?? "",
                workDir: viewModel.workDir ?? "",
                gitBranch: "",
                provider: viewModel.provider ?? .claude,
                onSave: { data in
                    viewModel.onEdit?(data)
                }
            )
        }
        .onAppear {
            isVisible = true
            if isFocused {
                viewModel.resumeRefresh()
            } else {
                viewModel.slowRefresh()
            }
            if let dir = viewModel.workDir, !dir.isEmpty {
                fileVM.loadDirectory(at: dir)
            }
        }
        .onDisappear {
            isVisible = false
            viewModel.pauseRefresh()
        }
        .onChange(of: isFocused) { _, focused in
            if focused {
                viewModel.resumeRefresh()
            } else {
                viewModel.slowRefresh()
            }
        }
    }

    // MARK: - Tab Content

    @AppStorage("useMetalRenderer") private var useMetalRenderer: Bool = true

    @ViewBuilder
    private var terminalContent: some View {
        if let command = viewModel.launchCommand {
            // All cards get a live terminal
            if useMetalRenderer && isMetalAvailable() {
                MetalTerminalView(
                    command: command,
                    workingDirectory: viewModel.workDir,
                    onProcessExit: { _ in
                        viewModel.state = .inactive
                    }
                )
                .id(terminalId)
                .frame(minHeight: 120)
            } else {
                TerminalEmulatorView(
                    command: command,
                    workingDirectory: viewModel.workDir,
                    onProcessExit: { _ in
                        viewModel.state = .inactive
                    }
                )
                .id(terminalId)
                .frame(minHeight: 120)
            }
        } else {
            ZStack {
                Color.black

                if viewModel.cleanOutput.isEmpty {
                    if viewModel.state == .working {
                        // Launching feedback — spinner + message
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.regular)
                                .tint(.green)
                            Text(L10n.Terminal.waiting)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.green.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text(L10n.Terminal.noOutput)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    ScrollView(.vertical) {
                        Text(viewModel.cleanOutput)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(8)
                            .textSelection(.enabled)
                    }
                }
            }
            .frame(minHeight: 80)
        }
    }

    /// Lightweight terminal preview — shows status badge + last output, no PTY process.
    private var terminalPreview: some View {
        ZStack {
            Color.black

            if viewModel.cleanOutput.isEmpty {
                VStack(spacing: 8) {
                    stateIcon
                    Text(viewModel.name)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("Click to activate terminal")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Show last lines of output as a lightweight snapshot
                VStack(spacing: 0) {
                    let lines = viewModel.cleanOutput.components(separatedBy: "\n")
                    let snapshot = lines.suffix(15).joined(separator: "\n")
                    Text(snapshot)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(6)
                        .lineLimit(15)
                }
            }

            // Status overlay badge — always visible
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    statusBadge
                        .padding(8)
                }
            }
        }
        .frame(minHeight: 120)
    }

    private var stateIcon: some View {
        Group {
            switch viewModel.state {
            case .working:
                Image(systemName: "progress.indicator")
                    .font(.title)
                    .foregroundStyle(.green)
                    .symbolEffect(.variableColor.iterative)
            case .needsInput:
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
            case .error:
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.red)
            case .inactive:
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.gray)
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(viewModel.borderColor)
                .frame(width: 6, height: 6)
            Text(viewModel.state.rawValue)
                .font(.system(size: 9, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var filesContent: some View {
        if viewModel.workDir != nil, !viewModel.workDir!.isEmpty {
            FileExplorerView(viewModel: fileVM)
        } else {
            Text(L10n.Terminal.noWorkdir)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Activity Tab Content

struct SessionActivityContent: View {
    let viewModel: SessionCardViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                if viewModel.activityEntries.isEmpty {
                    Text(L10n.Activity.noActivity)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                } else {
                    Text(L10n.Activity.recent)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.top, 8)

                    ForEach(viewModel.activityEntries) { entry in
                        HStack(spacing: 8) {
                            Text(entry.timeString)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .frame(width: 60, alignment: .leading)

                            Image(systemName: entry.icon)
                                .font(.caption)
                                .foregroundStyle(entry.color)
                                .frame(width: 14)

                            Text(entry.detail)
                                .font(.caption)
                                .lineLimit(2)
                                .foregroundStyle(.primary)

                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
    }
}

// MARK: - Info Tab Content

struct SessionInfoContent: View {
    let viewModel: SessionCardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                // Provider section
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(label: L10n.Info.provider, value: viewModel.provider?.displayName ?? "Unknown")
                        infoRow(label: L10n.Info.model, value: viewModel.modelName ?? "—")
                        infoRow(label: L10n.Info.state, value: viewModel.state.rawValue.capitalized, color: stateColor)
                    }
                } label: {
                    Label(L10n.Info.provider, systemImage: "cpu")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                // Session section
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(label: L10n.Info.name, value: viewModel.name)
                        infoRow(label: L10n.Info.sessionID, value: String(viewModel.sessionId.prefix(12)))
                        infoRow(label: L10n.Info.command, value: viewModel.launchCommand ?? "—", mono: true)
                        infoRow(label: L10n.Info.duration, value: viewModel.duration)
                        infoRow(label: L10n.Info.cost, value: viewModel.cost)
                    }
                } label: {
                    Label(L10n.Session.sectionSession, systemImage: "terminal")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                // Project section
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(label: L10n.Info.directory, value: shortenPath(viewModel.workDir ?? "—"), mono: true)
                        if let branch = viewModel.gitBranch {
                            infoRow(label: L10n.Info.branch, value: branch, mono: true, color: .cyan)
                        }
                    }
                } label: {
                    Label(L10n.Sidebar.projects, systemImage: "folder")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                // Links section — only shown when URLs are present in output
                if !viewModel.detectedLinks.isEmpty {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(viewModel.detectedLinks) { link in
                                Button {
                                    NSWorkspace.shared.open(link.url)
                                } label: {
                                    Text(link.label)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.blue)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.borderless)
                                .help(link.url.absoluteString)
                            }
                        }
                    } label: {
                        Label(L10n.Info.links, systemImage: "link")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(10)
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
    }

    private var stateColor: Color {
        switch viewModel.state {
        case .working: return .green
        case .needsInput: return .yellow
        case .error: return .red
        case .inactive: return .gray
        }
    }

    private func infoRow(label: String, value: String, mono: Bool = false, color: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(mono ? .system(.caption, design: .monospaced) : .caption)
                .foregroundStyle(color ?? .primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
    }

    private func shortenPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

// MARK: - Session Tab Bar

struct SessionTabBar: View {
    @Binding var selectedTab: SessionTab
    let onRefreshTerminal: () -> Void
    let onOpenDiff: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(SessionTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 9))
                        Text(tab.localizedTitle)
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
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
                HStack(spacing: 3) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 9))
                    Text(L10n.Tab.diff)
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
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
                .help(L10n.Tab.restartTerminal)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
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
    @State private var statusMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if loading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(L10n.Diff.loading)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if diffVM.hunks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text(statusMessage ?? L10n.Diff.noChanges)
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
        .onAppear {
            wireCallbacks()
            loadDiff()
        }
    }

    private func wireCallbacks() {
        diffVM.onApprove = { [self] in
            approveChanges()
        }
        diffVM.onReject = { [self] in
            rejectChanges()
        }
    }

    private func approveChanges() {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["add", "-A"]
            process.currentDirectoryURL = URL(fileURLWithPath: workDir)
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()
                DispatchQueue.main.async {
                    statusMessage = "Changes staged (git add -A)"
                    diffVM.hunks = []
                }
            } catch {}
        }
    }

    private func rejectChanges() {
        let alert = NSAlert()
        alert.messageText = L10n.Diff.rejectTitle
        alert.informativeText = L10n.Diff.rejectMessage(workDir)
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.Diff.discardChanges)
        alert.addButton(withTitle: L10n.cancel)

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["checkout", "--", "."]
            process.currentDirectoryURL = URL(fileURLWithPath: workDir)
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()
                DispatchQueue.main.async {
                    statusMessage = "Changes discarded (git checkout)"
                    diffVM.hunks = []
                }
            } catch {}
        }
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
    var onEdit: (() -> Void)?

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

            Button(action: { onEdit?() }) {
                Image(systemName: "pencil")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help(L10n.Session.editInfoHint)

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
    var onEdit: (() -> Void)?
    var onRename: ((String) -> Void)?
    var onKill: (() -> Void)?
    var onRestart: (() -> Void)?
    var onToggleRecording: (() -> Void)?
    var isRecording: Bool = false
    var onArchive: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        Button(L10n.Session.edit) {
            onEdit?()
        }
        Divider()
        Button(L10n.Session.rename) {
            onRename?(sessionName)
        }
        Button(L10n.Session.kill, role: .destructive) {
            onKill?()
        }
        Button(L10n.Session.restart) {
            onRestart?()
        }
        Divider()
        if projectPath != nil, !(projectPath?.isEmpty ?? true) {
            Button(L10n.Session.remix) { onRemix?() }
        }
        Button(isRecording ? L10n.Session.stopRecording : L10n.Session.startRecording) {
            onToggleRecording?()
        }
        Divider()
        Button(L10n.Session.archive) {
            onArchive?()
        }
        Button(L10n.Session.delete, role: .destructive) {
            confirmDelete()
        }
        Divider()
        Button(L10n.Session.copyID) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(sessionId, forType: .string)
        }
    }

    // MARK: - Delete Confirmation

    private func confirmDelete() {
        let alert = NSAlert()
        alert.messageText = L10n.Session.deleteTitle(sessionName)
        alert.informativeText = L10n.Session.deleteMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.delete)
        alert.addButton(withTitle: L10n.cancel)
        alert.buttons.first?.hasDestructiveAction = true

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        onDelete?()
    }
}

// MARK: - Detected Link

/// A URL found in terminal output, surfaced for one-click navigation.
// MARK: - Resource Links Panel (inspired by AgentHub)

struct ResourceLinksPanel: View {
    let links: [DetectedLink]
    let provider: AgentProvider?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()

            // Header — always visible, toggles expand/collapse
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    Text(L10n.Resources.title)
                        .font(.caption)
                        .fontWeight(.medium)

                    Text("\(links.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(links) { link in
                            ResourceLinkChip(link: link)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.primary.opacity(0.03))
    }
}

// MARK: - Resource Link Chip

private struct ResourceLinkChip: View {
    let link: DetectedLink
    @State private var isHovering = false

    var body: some View {
        Button(action: { NSWorkspace.shared.open(link.url) }) {
            HStack(spacing: 4) {
                Image(systemName: iconForURL(link.url))
                    .font(.caption2)

                VStack(alignment: .leading, spacing: 0) {
                    Text(link.label)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(link.url.host ?? "")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isHovering ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(link.url.absoluteString)
    }

    private func iconForURL(_ url: URL) -> String {
        let host = url.host?.lowercased() ?? ""
        if host.contains("github.com") { return "curlybraces" }
        if host.contains("docs.") || host.contains("documentation") { return "doc.text" }
        if host.contains("stackoverflow.com") { return "questionmark.circle" }
        if host.contains("npm") || host.contains("pypi") || host.contains("crates.io") { return "shippingbox" }
        if host.contains("slack") { return "bubble.left.and.bubble.right" }
        if host.contains("linear") || host.contains("jira") { return "ticket" }
        return "globe"
    }
}

// MARK: - Detected Link

struct DetectedLink: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let label: String

    static func == (lhs: DetectedLink, rhs: DetectedLink) -> Bool {
        lhs.url == rhs.url
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
    var gitBranch: String?
    var activityEntries: [SessionActivityEntry] = []
    var detectedLinks: [DetectedLink] = []
    var onRemix: (() -> Void)?
    var onKill: (() -> Void)?
    var onRestart: (() -> Void)?
    var onRename: ((String) -> Void)?
    var onEdit: ((SessionEditData) -> Void)?
    var onToggleRecording: (() -> Void)?
    var isRecording: Bool = false
    var onArchive: (() -> Void)?
    var onDelete: (() -> Void)?

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
        self.gitBranch = session.gitBranch
        // Timer starts only when view becomes visible (resumeRefresh)
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

    /// Start fast refresh (1s) for visible/focused cards.
    func resumeRefresh() {
        guard refreshTimer == nil else { return }
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    /// Switch to slow refresh (5s) — just state updates, no heavy output polling.
    func slowRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshStateOnly()
        }
    }

    func pauseRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func refreshStateOnly() {
        guard let session else {
            refreshTimer?.invalidate()
            return
        }
        let newState = session.state
        if newState != lastState {
            addActivity(icon: newState.activityIcon, color: newState.activityColor, detail: newState.rawValue.capitalized)
            lastState = newState
        }
        if state != newState { state = newState }
        let newCost = Self.formatCost(session.totalCost)
        if cost != newCost { cost = newCost }
        let newDuration = Self.formatDuration(since: session.startTime)
        if duration != newDuration { duration = newDuration }
    }

    private var lastState: AgentState = .inactive

    private func refresh() {
        guard let session else {
            refreshTimer?.invalidate()
            return
        }
        let newState = session.state
        if newState != lastState {
            addActivity(icon: newState.activityIcon, color: newState.activityColor, detail: newState.rawValue.capitalized)
            lastState = newState
        }
        if state != newState { state = newState }
        let newCost = Self.formatCost(session.totalCost)
        if cost != newCost { cost = newCost }
        let newDuration = Self.formatDuration(since: session.startTime)
        if duration != newDuration { duration = newDuration }
        let newOutput = session.outputText
        if newOutput != lastOutput {
            lastOutput = newOutput
            detectedLinks = Self.extractLinks(from: newOutput)
        }
        let newBranch = session.gitBranch
        if newBranch != gitBranch {
            gitBranch = newBranch
        }
    }

    func addActivity(icon: String, color: Color, detail: String) {
        let entry = SessionActivityEntry(time: Date(), icon: icon, color: color, detail: detail)
        activityEntries.insert(entry, at: 0)
        if activityEntries.count > 100 {
            activityEntries.removeLast()
        }
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

    /// Scans `text` for http/https URLs and returns deduplicated DetectedLinks.
    /// Uses NSRegularExpression so no third-party dependency is needed.
    private static func extractLinks(from text: String) -> [DetectedLink] {
        guard !text.isEmpty,
              let regex = try? NSRegularExpression(pattern: #"https?://[^\s<>"']+"#)
        else { return [] }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        var seen = Set<URL>()
        var links: [DetectedLink] = []

        for match in matches {
            guard let swiftRange = Range(match.range, in: text) else { continue }
            let rawString = String(text[swiftRange])
            // Trim trailing punctuation that is unlikely to be part of the URL
            let trimmed = rawString.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:)]}\"'"))
            guard let url = URL(string: trimmed), !seen.contains(url) else { continue }
            seen.insert(url)
            links.append(DetectedLink(url: url, label: trimmed))
        }

        return links
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

// MARK: - Activity Entry

struct SessionActivityEntry: Identifiable {
    let id = UUID()
    let time: Date
    let icon: String
    let color: Color
    let detail: String

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: time)
    }
}

// MARK: - AgentState Activity Helpers

private extension AgentState {
    var activityIcon: String {
        switch self {
        case .working: return "hammer.fill"
        case .needsInput: return "questionmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .inactive: return "circle.fill"
        }
    }

    var activityColor: Color {
        switch self {
        case .working: return .green
        case .needsInput: return .yellow
        case .error: return .red
        case .inactive: return .gray
        }
    }
}
