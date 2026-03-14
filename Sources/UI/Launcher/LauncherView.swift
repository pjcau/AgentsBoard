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
                print("[Launcher] onLaunch callback fired with \(entries.count) entries")
                onLaunch(entries)
                print("[Launcher] Calling dismiss")
                self?.dismiss()
            },
            onCancel: { [weak self] in
                print("[Launcher] Cancel pressed")
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
            }, onCloneRepo: {
                presentClonePanel(entries: $entries)
            }, onLaunch: {
                let valid = entries.filter { !$0.command.trimmingCharacters(in: .whitespaces).isEmpty }
                print("[LauncherContent] Launch pressed. \(entries.count) entries, \(valid.count) valid")
                guard !valid.isEmpty else {
                    print("[LauncherContent] No valid entries — aborting")
                    return
                }
                let launchEntries = valid.map { data in
                    var entry = LaunchEntry()
                    entry.name = data.name
                    entry.provider = data.provider
                    entry.command = data.command
                    entry.workDir = data.workDir
                    return entry
                }
                print("[LauncherContent] Calling onLaunch with \(launchEntries.count) entries")
                onLaunch(launchEntries)
            })
        }
    }

}

// MARK: - Clone Panel Presenter (uses NSPanel, not .sheet — avoids blocking parent NSWindow)

private func presentClonePanel(entries: Binding<[LaunchEntryData]>) {
    let panel = NSPanel(
        contentRect: NSRect(x: 0, y: 0, width: 480, height: 340),
        styleMask: [.titled, .closable, .utilityWindow],
        backing: .buffered,
        defer: false
    )
    panel.title = L10n.Launcher.cloneTitle
    panel.center()
    panel.isReleasedWhenClosed = false

    weak var weakPanel = panel
    let entriesBinding = entries
    let view = CloneRepoSheet(isPresented: .constant(true), onCloned: { clonedPath in
        if let repo = detectRepo(at: clonedPath) {
            var entry = LaunchEntryData()
            entry.name = repo.name
            entry.provider = repo.suggestedProvider
            entry.command = repo.suggestedProvider.defaultCommand
            entry.workDir = repo.path
            entriesBinding.wrappedValue.append(entry)
        }
        weakPanel?.close()
    })
    panel.contentView = NSHostingView(rootView: view)
    panel.makeKeyAndOrderFront(nil)
}

// MARK: - Clone Repository Sheet

private struct CloneRepoSheet: View {
    @Binding var isPresented: Bool
    let onCloned: (String) -> Void

    @State private var repoURL = ""
    @State private var destinationDir = defaultCloneDir()
    @State private var isCloning = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.Launcher.cloneTitle)
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                // Git URL field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Git URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("https://github.com/user/repo.git", text: $repoURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                // Destination directory
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Launcher.cloneDestination)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        TextField("~/Projects", text: $destinationDir)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                        Button {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = false
                            if !destinationDir.isEmpty {
                                panel.directoryURL = URL(fileURLWithPath: destinationDir)
                            }
                            if panel.runModal() == .OK, let url = panel.url {
                                destinationDir = url.path
                            }
                        } label: {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                // Repo name preview
                if let repoName = extractRepoName(from: repoURL) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption)
                        Text(repoName)
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                        Text(destinationDir + "/" + repoName)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.head)
                    }
                    .foregroundStyle(.secondary)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()

            Divider()

            HStack {
                Spacer()
                Button(L10n.cancel) { isPresented = false }
                    .keyboardShortcut(.cancelAction)

                Button(action: cloneRepo) {
                    if isCloning {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 4)
                    } else {
                        Text(L10n.Launcher.cloneButton)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(repoURL.trimmingCharacters(in: .whitespaces).isEmpty || isCloning)
            }
            .padding()
        }
        .frame(width: 480, height: 340)
    }

    private func cloneRepo() {
        let url = repoURL.trimmingCharacters(in: .whitespaces)
        guard !url.isEmpty else { return }
        guard let repoName = extractRepoName(from: url) else {
            errorMessage = "Invalid Git URL"
            return
        }

        let dest = (destinationDir as NSString).expandingTildeInPath
        let targetPath = (dest as NSString).appendingPathComponent(repoName)

        // Check if already exists
        if FileManager.default.fileExists(atPath: targetPath) {
            // Already cloned — just use it
            isPresented = false
            onCloned(targetPath)
            return
        }

        isCloning = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            let errPipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["clone", url, targetPath]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = errPipe

            do {
                try process.run()
                process.waitUntilExit()

                let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                let errStr = String(data: errData, encoding: .utf8) ?? ""

                DispatchQueue.main.async {
                    isCloning = false
                    if process.terminationStatus == 0 {
                        isPresented = false
                        onCloned(targetPath)
                    } else {
                        errorMessage = errStr.isEmpty ? "Clone failed (exit \(process.terminationStatus))" : errStr.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isCloning = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private static func defaultCloneDir() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let projects = (home as NSString).appendingPathComponent("Projects")
        if FileManager.default.fileExists(atPath: projects) { return projects }
        let dev = (home as NSString).appendingPathComponent("Developer")
        if FileManager.default.fileExists(atPath: dev) { return dev }
        return (home as NSString).appendingPathComponent("Documents")
    }
}

private func extractRepoName(from urlString: String) -> String? {
    let trimmed = urlString.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return nil }
    // Handle both https://github.com/user/repo.git and git@github.com:user/repo.git
    let cleaned = trimmed.hasSuffix(".git") ? String(trimmed.dropLast(4)) : trimmed
    if let lastSlash = cleaned.lastIndex(of: "/") {
        let name = String(cleaned[cleaned.index(after: lastSlash)...])
        return name.isEmpty ? nil : name
    }
    if let lastColon = cleaned.lastIndex(of: ":") {
        let afterColon = String(cleaned[cleaned.index(after: lastColon)...])
        if let lastSlash = afterColon.lastIndex(of: "/") {
            return String(afterColon[afterColon.index(after: lastSlash)...])
        }
        return afterColon.isEmpty ? nil : afterColon
    }
    return nil
}

// MARK: - Footer

private struct LauncherFooter: View {
    @Binding var entries: [LaunchEntryData]
    let onAdd: () -> Void
    let onCloneRepo: () -> Void
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

            Button(action: onCloneRepo) {
                Label(L10n.Launcher.cloneButton, systemImage: "arrow.down.circle")
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
