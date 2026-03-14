// MARK: - Smart Mode Launcher Tab
// AI-planned task distribution: describe what you want, get provider suggestions.

import SwiftUI
import AppKit
import AgentsBoardCore

struct SmartLauncherTab: View {
    let taskRouter: TaskRouter
    let onLaunch: ([LaunchEntry]) -> Void
    let onCancel: () -> Void

    @State private var objective: String = ""
    @State private var suggestion: RoutingSuggestion?
    @State private var workDir: String = ""
    @State private var sessionCount: Int = 1
    @State private var planned = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.title2)
                    .foregroundStyle(.purple)
                VStack(alignment: .leading) {
                    Text("Smart Mode")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Describe your task — we'll suggest the best agent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel", action: onCancel)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Objective input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What do you want to accomplish?")
                            .font(.callout)
                            .fontWeight(.medium)
                        TextEditor(text: $objective)
                            .font(.body)
                            .frame(minHeight: 80, maxHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.secondary.opacity(0.2))
                            )
                    }

                    // Working directory
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Working Directory")
                            .font(.callout)
                            .fontWeight(.medium)
                        HStack {
                            TextField("Project path", text: $workDir)
                                .textFieldStyle(.roundedBorder)
                            Button {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = false
                                panel.canChooseDirectories = true
                                panel.allowsMultipleSelection = false
                                if panel.runModal() == .OK, let url = panel.url {
                                    workDir = url.path
                                }
                            } label: {
                                Image(systemName: "folder")
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    // Plan button
                    if !planned {
                        Button {
                            plan()
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Plan")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(objective.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    // Suggestion card
                    if let suggestion {
                        suggestionCard(suggestion)
                    }
                }
                .padding(16)
            }

            if planned {
                Divider()

                // Launch footer
                HStack {
                    Stepper("Sessions: \(sessionCount)", value: $sessionCount, in: 1...5)
                        .font(.callout)

                    Spacer()

                    Button("Launch (\(sessionCount))") {
                        launch()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(16)
            }
        }
    }

    private func plan() {
        guard !objective.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        suggestion = taskRouter.suggest(taskDescription: objective)
        planned = true
    }

    private func launch() {
        guard let suggestion else { return }
        var entries: [LaunchEntry] = []
        for i in 0..<sessionCount {
            var entry = LaunchEntry()
            entry.name = sessionCount > 1 ? "\(suggestion.provider.rawValue.capitalized) #\(i + 1)" : suggestion.provider.rawValue.capitalized
            entry.provider = suggestion.provider
            entry.command = suggestion.provider.defaultCommand
            entry.workDir = workDir
            entries.append(entry)
        }
        onLaunch(entries)
    }

    @ViewBuilder
    private func suggestionCard(_ s: RoutingSuggestion) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundStyle(.purple)
                    Text("Recommended")
                        .font(.callout)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(Int(s.confidence * 100))% match")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.15))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Provider")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(s.provider.rawValue.capitalized)
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    Divider().frame(height: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Model")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(s.model)
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                }

                Text(s.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(4)
        }
    }
}

// Note: AgentProvider.defaultCommand and .displayName are defined in Core/Agent/AgentModels.swift
