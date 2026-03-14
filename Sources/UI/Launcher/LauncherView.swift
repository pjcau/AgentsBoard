// MARK: - Multi-Session Launcher (Step 14.1)
//
// Uses a standalone NSPanel instead of SwiftUI .sheet to guarantee
// proper first-responder/TextField focus on macOS.

import SwiftUI
import AppKit
import AgentsBoardCore

// MARK: - Keyable Window (NSWindow that always accepts key status)

private class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Window-based Launcher Presenter

public final class LauncherPresenter {
    private var window: NSWindow?
    private var onLaunch: (([LaunchEntry]) -> Void)?
    public var taskRouter: TaskRouter?

    public init() {}

    public func present(onLaunch: @escaping ([LaunchEntry]) -> Void) {
        // If already showing, bring to front
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        self.onLaunch = onLaunch

        let view = LauncherContentView(
            taskRouter: taskRouter,
            onLaunch: { [weak self] entries in
                onLaunch(entries)
                self?.dismiss()
            },
            onCancel: { [weak self] in
                self?.dismiss()
            }
        )

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 550, height: 480)

        // Use NSWindow (not NSPanel) with canBecomeKey override
        let window = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Launch Sessions"
        window.contentView = hostingView
        window.minSize = NSSize(width: 450, height: 350)
        window.maxSize = NSSize(width: 700, height: 700)
        window.center()
        window.isReleasedWhenClosed = false

        // Critical: make this the key window so TextFields receive keyboard input
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Force first responder to the hosting view so SwiftUI can manage focus
        window.makeFirstResponder(hostingView)

        self.window = window
    }

    public func dismiss() {
        window?.close()
        window = nil
    }
}

// MARK: - Launcher Content (SwiftUI view hosted in NSPanel)

private enum LauncherTab: String, CaseIterable {
    case manual = "Manual"
    case smart = "Smart Mode"
}

private struct LauncherContentView: View {
    let taskRouter: TaskRouter?
    let onLaunch: ([LaunchEntry]) -> Void
    let onCancel: () -> Void

    @State private var entries: [LaunchEntryData] = [LaunchEntryData()]
    @State private var selectedTab: LauncherTab = .manual

    var body: some View {
        VStack(spacing: 0) {
            // Header with tabs
            VStack(spacing: 8) {
                HStack {
                    Text("Launch Sessions")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Cancel", action: onCancel)
                }

                if taskRouter != nil {
                    Picker("", selection: $selectedTab) {
                        ForEach(LauncherTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(16)

            Divider()

            // Tab content
            switch selectedTab {
            case .manual:
                manualContent
            case .smart:
                if let router = taskRouter {
                    SmartLauncherTab(
                        taskRouter: router,
                        onLaunch: onLaunch,
                        onCancel: onCancel
                    )
                }
            }
        }
    }

    private var manualContent: some View {
        VStack(spacing: 0) {
            // Entry list
            ScrollView {
                VStack(spacing: 16) {
                    ForEach($entries) { $entry in
                        LaunchEntryRow(entry: $entry, canRemove: entries.count > 1) {
                            entries.removeAll { $0.id == entry.id }
                        }
                    }
                }
                .padding(16)
            }

            Divider()

            // Footer
            LauncherFooter(entries: $entries, onAdd: {
                entries.append(LaunchEntryData())
            }, onAddFromRepo: {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = true
                panel.message = L10n.Launcher.selectRepo
                panel.prompt = L10n.Launcher.openRepo
                if panel.runModal() == .OK {
                    for url in panel.urls {
                        if let repo = detectRepo(at: url.path) {
                            var entry = LaunchEntryData()
                            entry.name = repo.name
                            entry.provider = repo.suggestedProvider
                            entry.command = repo.suggestedProvider.defaultCommand
                            entry.workDir = repo.path
                            entries.append(entry)
                        } else {
                            // Not a git repo — still add with directory
                            var entry = LaunchEntryData()
                            entry.name = url.lastPathComponent
                            entry.workDir = url.path
                            entries.append(entry)
                        }
                    }
                }
            }, onLaunch: {
                let valid = entries.filter { !$0.command.trimmingCharacters(in: .whitespaces).isEmpty }
                guard !valid.isEmpty else { return }
                let launchEntries = valid.map { data in
                    var entry = LaunchEntry()
                    entry.name = data.name
                    entry.provider = data.provider
                    entry.command = data.command
                    entry.workDir = data.workDir
                    return entry
                }
                onLaunch(launchEntries)
            })
        }
    }
}

// MARK: - Footer

private struct LauncherFooter: View {
    @Binding var entries: [LaunchEntryData]
    let onAdd: () -> Void
    let onAddFromRepo: () -> Void
    let onLaunch: () -> Void

    private var validCount: Int {
        entries.filter { !$0.command.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }

    var body: some View {
        HStack {
            Button(action: onAdd) {
                Label(L10n.Launcher.addSession, systemImage: "plus")
            }
            .buttonStyle(.borderless)

            Button(action: onAddFromRepo) {
                Label(L10n.Launcher.fromRepo, systemImage: "folder.badge.gearshape")
            }
            .buttonStyle(.borderless)

            Spacer()

            if validCount == 0 {
                Text(L10n.Launcher.enterCommand)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Button(L10n.Launcher.launch(validCount > 0 ? "(\(validCount))" : ""), action: onLaunch)
                .buttonStyle(.borderedProminent)
                .disabled(validCount == 0)
        }
        .padding(16)
    }
}

// MARK: - Entry Row

private struct LaunchEntryRow: View {
    @Binding var entry: LaunchEntryData
    let canRemove: Bool
    let onRemove: () -> Void

    /// Whether the command was auto-filled (user hasn't manually edited it)
    @State private var commandAutoFilled = true

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("Name") {
                    TextField("Session name", text: $entry.name)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledContent("Provider") {
                    Picker("", selection: $entry.provider) {
                        ForEach(AgentProvider.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: entry.provider) { _, newProvider in
                        // Auto-fill command and name when provider changes
                        if commandAutoFilled || entry.command.isEmpty {
                            entry.command = newProvider.defaultCommand
                            commandAutoFilled = true
                        }
                        if entry.name.isEmpty {
                            entry.name = newProvider.displayName
                        }
                    }
                }
                LabeledContent("Command") {
                    TextField("e.g. claude, aider, codex", text: $entry.command)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: entry.command) { _, _ in
                            // If user manually edits, stop auto-filling
                            commandAutoFilled = false
                        }
                }
                LabeledContent("Directory") {
                    HStack {
                        TextField(L10n.Session.workdirPlaceholder, text: $entry.workDir)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = false
                            panel.message = L10n.Session.selectWorkdir
                            if panel.runModal() == .OK, let url = panel.url {
                                entry.workDir = url.path
                                // Auto-detect repo info
                                if let repo = detectRepo(at: url.path) {
                                    if entry.name.isEmpty || entry.name == entry.provider.displayName {
                                        entry.name = repo.name
                                    }
                                    entry.provider = repo.suggestedProvider
                                    if commandAutoFilled || entry.command.isEmpty {
                                        entry.command = repo.suggestedProvider.defaultCommand
                                        commandAutoFilled = true
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                if canRemove {
                    HStack {
                        Spacer()
                        Button("Remove", role: .destructive, action: onRemove)
                            .buttonStyle(.borderless)
                    }
                }
            }
            .padding(4)
        }
    }
}

// MARK: - Repository Detection

private struct RepoInfo {
    let name: String
    let path: String
    let branch: String?
    let suggestedProvider: AgentProvider
}

private func detectRepo(at path: String) -> RepoInfo? {
    let url = URL(fileURLWithPath: path)
    let gitDir = url.appendingPathComponent(".git")
    guard FileManager.default.fileExists(atPath: gitDir.path) else { return nil }

    let repoName = url.lastPathComponent

    // Detect branch
    let branch: String? = {
        let headFile = gitDir.appendingPathComponent("HEAD")
        guard let content = try? String(contentsOf: headFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        if content.hasPrefix("ref: refs/heads/") {
            return String(content.dropFirst("ref: refs/heads/".count))
        }
        return String(content.prefix(8))
    }()

    // Detect provider from project files
    let provider: AgentProvider = {
        let fm = FileManager.default
        if fm.fileExists(atPath: url.appendingPathComponent("CLAUDE.md").path) ||
           fm.fileExists(atPath: url.appendingPathComponent(".claude").path) {
            return .claude
        }
        if fm.fileExists(atPath: url.appendingPathComponent(".aider.conf.yml").path) {
            return .aider
        }
        return .claude // default
    }()

    return RepoInfo(name: repoName, path: path, branch: branch, suggestedProvider: provider)
}

// MARK: - Data Model

struct LaunchEntryData: Identifiable {
    let id = UUID()
    var name: String = "Claude"
    var provider: AgentProvider = .claude
    var command: String = "claude"
    var workDir: String = ""
}

// MARK: - Public LaunchEntry (for cross-module API)

public struct LaunchEntry: Identifiable {
    public let id = UUID()
    public var name: String = ""
    public var provider: AgentProvider = .claude
    public var command: String = ""
    public var workDir: String = ""
    public var isEnabled: Bool = true
}
