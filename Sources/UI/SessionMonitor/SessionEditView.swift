// MARK: - Session Edit View
// Allows editing session info: name, command, working directory, git branch.

import SwiftUI
import AgentsBoardCore

struct SessionEditView: View {
    @Binding var isPresented: Bool
    @State var name: String
    @State var command: String
    @State var workDir: String
    @State var gitBranch: String
    @State var provider: AgentProvider

    let onSave: (SessionEditData) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(L10n.Session.editTitle)
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

            // Form
            Form {
                Section(L10n.Session.sectionSession) {
                    TextField("Name", text: $name)
                    Picker("Provider", selection: $provider) {
                        ForEach(AgentProvider.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(L10n.Session.sectionExecution) {
                    TextField("Command", text: $command)
                        .font(.system(.body, design: .monospaced))
                    HStack {
                        TextField("Working Directory", text: $workDir)
                            .font(.system(.body, design: .monospaced))
                        Button(action: pickDirectory) {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Section(L10n.Session.sectionGit) {
                    TextField("Branch", text: $gitBranch)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

            // Actions
            HStack {
                Spacer()
                Button(L10n.cancel) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button(L10n.save) {
                    let data = SessionEditData(
                        name: name.trimmingCharacters(in: .whitespaces),
                        command: command.trimmingCharacters(in: .whitespaces),
                        workDir: workDir.trimmingCharacters(in: .whitespaces),
                        gitBranch: gitBranch.trimmingCharacters(in: .whitespaces),
                        provider: provider
                    )
                    onSave(data)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 420, height: 380)
    }

    private func pickDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if !workDir.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: workDir)
        }
        if panel.runModal() == .OK, let url = panel.url {
            workDir = url.path
        }
    }
}

// MARK: - Edit Data

struct SessionEditData {
    let name: String
    let command: String
    let workDir: String
    let gitBranch: String
    let provider: AgentProvider
}
