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

    public init() {}

    public func present(onLaunch: @escaping ([LaunchEntry]) -> Void) {
        // If already showing, bring to front
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        self.onLaunch = onLaunch

        let view = LauncherContentView(onLaunch: { [weak self] entries in
            onLaunch(entries)
            self?.dismiss()
        }, onCancel: { [weak self] in
            self?.dismiss()
        })

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

private struct LauncherContentView: View {
    let onLaunch: ([LaunchEntry]) -> Void
    let onCancel: () -> Void

    @State private var entries: [LaunchEntryData] = [LaunchEntryData()]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Launch Sessions")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel", action: onCancel)
            }
            .padding(16)

            Divider()

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
    let onLaunch: () -> Void

    private var validCount: Int {
        entries.filter { !$0.command.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }

    var body: some View {
        HStack {
            Button(action: onAdd) {
                Label("Add Session", systemImage: "plus")
            }
            .buttonStyle(.borderless)

            Spacer()

            if validCount == 0 {
                Text("Enter a command to launch")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Button("Launch \(validCount > 0 ? "(\(validCount))" : "")", action: onLaunch)
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
                        TextField("Working directory (optional)", text: $entry.workDir)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = false
                            panel.canChooseDirectories = true
                            panel.allowsMultipleSelection = false
                            panel.message = "Select working directory"
                            if panel.runModal() == .OK, let url = panel.url {
                                entry.workDir = url.path
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

// MARK: - Data Model

struct LaunchEntryData: Identifiable {
    let id = UUID()
    var name: String = "Claude"
    var provider: AgentProvider = .claude
    var command: String = "claude"
    var workDir: String = ""
}

// MARK: - Provider Helpers

extension AgentProvider {
    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .codex: return "Codex"
        case .aider: return "Aider"
        case .gemini: return "Gemini"
        case .custom: return "Custom"
        }
    }

    var defaultCommand: String {
        switch self {
        case .claude: return "claude"
        case .codex: return "codex"
        case .aider: return "aider"
        case .gemini: return "gemini"
        case .custom: return ""
        }
    }
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
