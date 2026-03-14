// MARK: - Remix Sheet (Session → Git Worktree with Context Transfer)

import SwiftUI
import AppKit
import AgentsBoardCore

/// NSPanel-based presenter for the Remix Sheet.
public final class RemixSheetPresenter {
    private var window: NSWindow?

    public init() {}

    public func present(
        sessionId: String,
        sessionName: String,
        projectPath: String,
        onRemix: @escaping (UIRemixConfig) -> Void
    ) {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let view = RemixSheetContent(
            sessionName: sessionName,
            projectPath: projectPath,
            onRemix: { config in
                onRemix(config)
                self.dismiss()
            },
            onCancel: { self.dismiss() }
        )

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 480, height: 420)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Remix Session — \(sessionName)"
        window.contentView = hostingView
        window.minSize = NSSize(width: 400, height: 350)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    public func dismiss() {
        window?.close()
        window = nil
    }
}

/// Configuration passed back from the remix UI.
public struct UIRemixConfig {
    public let branchName: String
    public let targetProvider: AgentProvider
    public let contextDepth: ContextDepth
    public let projectPath: String
}

// MARK: - Remix Sheet Content

private struct RemixSheetContent: View {
    let sessionName: String
    let projectPath: String
    let onRemix: (UIRemixConfig) -> Void
    let onCancel: () -> Void

    @State private var branchName: String = ""
    @State private var targetProvider: AgentProvider = .claude
    @State private var contextDepth: ContextDepth = .summary

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .font(.title2)
                    .foregroundStyle(.cyan)
                VStack(alignment: .leading) {
                    Text("Remix to Worktree")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Fork \"\(sessionName)\" into an isolated branch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)

            Divider()

            // Form
            Form {
                Section("Branch") {
                    TextField("Branch name", text: $branchName)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Image(systemName: "folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(shortenPath(projectPath))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    if !branchName.isEmpty {
                        HStack {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(worktreePath)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }

                Section("New Session") {
                    Picker("Provider", selection: $targetProvider) {
                        ForEach(AgentProvider.allCases, id: \.self) { p in
                            Text(p.rawValue.capitalized).tag(p)
                        }
                    }
                }

                Section("Context Transfer") {
                    Picker("Depth", selection: $contextDepth) {
                        ForEach(ContextDepth.allCases, id: \.self) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(contextDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

            // Footer
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Remix") {
                    onRemix(UIRemixConfig(
                        branchName: branchName,
                        targetProvider: targetProvider,
                        contextDepth: contextDepth,
                        projectPath: projectPath
                    ))
                }
                .buttonStyle(.borderedProminent)
                .disabled(branchName.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .onAppear {
            branchName = "remix/\(sessionName.lowercased().replacingOccurrences(of: " ", with: "-"))"
        }
    }

    private var worktreePath: String {
        projectPath + "-worktrees/" + branchName
    }

    private var contextDescription: String {
        switch contextDepth {
        case .summary: return "Transfer a brief summary of the session's work"
        case .lastNActions: return "Transfer the most recent actions and decisions"
        case .fullTranscript: return "Transfer the complete session transcript"
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
