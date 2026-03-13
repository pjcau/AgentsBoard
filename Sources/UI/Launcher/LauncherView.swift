// MARK: - Multi-Session Launcher (Step 14.1)
// Launch N agent sessions in parallel with one click.

import SwiftUI
import AgentsBoardCore

struct LauncherView: View {
    @Bindable var viewModel: LauncherViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Launch Sessions")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)

            // Tabs
            Picker("Mode", selection: $viewModel.mode) {
                Text("Manual").tag(LaunchMode.manual)
                Text("Config").tag(LaunchMode.config)
                Text("Smart").tag(LaunchMode.smart)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            Divider().padding(.top, 8)

            // Content
            ScrollView {
                switch viewModel.mode {
                case .manual:
                    ManualLaunchContent(viewModel: viewModel)
                case .config:
                    ConfigLaunchContent(viewModel: viewModel)
                case .smart:
                    SmartLaunchContent(viewModel: viewModel)
                }
            }

            Divider()

            // Footer
            HStack {
                Text("\(viewModel.sessionCount) sessions to launch")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Launch All") {
                    viewModel.launch()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.sessionCount == 0)
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Manual Launch

struct ManualLaunchContent: View {
    @Bindable var viewModel: LauncherViewModel

    var body: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.manualEntries.indices, id: \.self) { index in
                ManualSessionEntry(entry: $viewModel.manualEntries[index]) {
                    viewModel.removeManualEntry(at: index)
                }
            }

            Button {
                viewModel.addManualEntry()
            } label: {
                Label("Add Session", systemImage: "plus")
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
    }
}

struct ManualSessionEntry: View {
    @Binding var entry: LaunchEntry
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Picker("Provider", selection: $entry.provider) {
                ForEach(AgentProvider.allCases, id: \.self) { p in
                    Text(p.rawValue.capitalized).tag(p)
                }
            }
            .frame(maxWidth: 120)

            TextField("Command", text: $entry.command)
                .textFieldStyle(.roundedBorder)

            TextField("Working Dir", text: $entry.workDir)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)

            Button { onRemove() } label: {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Config Launch

struct ConfigLaunchContent: View {
    @Bindable var viewModel: LauncherViewModel

    var body: some View {
        VStack(spacing: 8) {
            if viewModel.configEntries.isEmpty {
                Text("No sessions defined in agentsboard.yml")
                    .foregroundStyle(.secondary)
                    .padding(40)
            } else {
                ForEach(viewModel.configEntries.indices, id: \.self) { index in
                    HStack {
                        Toggle(isOn: $viewModel.configEntries[index].isEnabled) {
                            VStack(alignment: .leading) {
                                Text(viewModel.configEntries[index].name)
                                    .font(.callout)
                                Text(viewModel.configEntries[index].command)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Smart Launch

struct SmartLaunchContent: View {
    @Bindable var viewModel: LauncherViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Describe your goal and let AI plan the sessions")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextEditor(text: $viewModel.smartGoal)
                .font(.body)
                .frame(minHeight: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary))

            if viewModel.isPlanning {
                ProgressView("Planning...")
            }

            Button("Generate Plan") {
                viewModel.generateSmartPlan()
            }
            .disabled(viewModel.smartGoal.isEmpty || viewModel.isPlanning)

            if !viewModel.smartPlanEntries.isEmpty {
                Divider()
                Text("Proposed Sessions")
                    .font(.callout)
                    .fontWeight(.medium)
                ForEach(viewModel.smartPlanEntries, id: \.name) { entry in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(entry.name)
                            .font(.callout)
                        Spacer()
                        Text(entry.provider.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Models

enum LaunchMode { case manual, config, smart }

struct LaunchEntry: Identifiable {
    let id = UUID()
    var name: String = ""
    var provider: AgentProvider = .claude
    var command: String = ""
    var workDir: String = ""
    var isEnabled: Bool = true
}

// MARK: - View Model

@Observable
final class LauncherViewModel {
    var mode: LaunchMode = .manual
    var manualEntries: [LaunchEntry] = [LaunchEntry()]
    var configEntries: [LaunchEntry] = []
    var smartGoal: String = ""
    var smartPlanEntries: [LaunchEntry] = []
    var isPlanning: Bool = false

    var onLaunch: (([LaunchEntry]) -> Void)?

    var sessionCount: Int {
        switch mode {
        case .manual: return manualEntries.count
        case .config: return configEntries.filter(\.isEnabled).count
        case .smart: return smartPlanEntries.count
        }
    }

    func addManualEntry() {
        manualEntries.append(LaunchEntry())
    }

    func removeManualEntry(at index: Int) {
        guard manualEntries.count > 1 else { return }
        manualEntries.remove(at: index)
    }

    func generateSmartPlan() {
        isPlanning = true
        // In real impl, calls an AI agent to plan
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isPlanning = false
        }
    }

    func launch() {
        let entries: [LaunchEntry]
        switch mode {
        case .manual: entries = manualEntries
        case .config: entries = configEntries.filter(\.isEnabled)
        case .smart: entries = smartPlanEntries
        }
        onLaunch?(entries)
    }
}
