// MARK: - Sidebar View (Step 5.3)

import SwiftUI
import AgentsBoardCore

struct SidebarView: View {
    @Bindable var viewModel: SidebarViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search sessions...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.ultraThinMaterial)

            // Segmented control
            Picker("View", selection: $viewModel.viewMode) {
                Text("All").tag(SidebarViewMode.all)
                Text("Projects").tag(SidebarViewMode.byProject)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            // Session list
            ScrollView {
                LazyVStack(spacing: 2) {
                    switch viewModel.viewMode {
                    case .all:
                        ForEach(viewModel.filteredSessions, id: \.sessionId) { session in
                            SessionListItem(session: session, isSelected: viewModel.selectedSessionId == session.sessionId)
                                .onTapGesture {
                                    viewModel.selectedSessionId = session.sessionId
                                }
                        }
                    case .byProject:
                        ForEach(viewModel.projectGroups, id: \.name) { group in
                            ProjectTreeItem(group: group, viewModel: viewModel)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Session List Item

struct SessionListItem: View {
    let session: SidebarSessionInfo
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stateColor(session.state))
                .frame(width: 8, height: 8)

            Image(systemName: providerIcon(session.provider))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(session.name)
                    .font(.callout)
                    .lineLimit(1)
                if let model = session.modelName {
                    Text(model)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if session.state == .needsInput {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func stateColor(_ state: AgentState) -> Color {
        switch state {
        case .working: return .green
        case .needsInput: return .yellow
        case .error: return .red
        case .inactive: return .gray
        }
    }

    private func providerIcon(_ provider: AgentProvider?) -> String {
        switch provider {
        case .claude: return "brain.head.profile"
        case .codex: return "chevron.left.forwardslash.chevron.right"
        case .aider: return "wrench.and.screwdriver"
        case .gemini: return "sparkles"
        case .custom, .none: return "terminal"
        }
    }
}

// MARK: - Project Tree Item

struct ProjectTreeItem: View {
    let group: ProjectGroup
    @Bindable var viewModel: SidebarViewModel

    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(group.sessions, id: \.sessionId) { session in
                SessionListItem(session: session, isSelected: viewModel.selectedSessionId == session.sessionId)
                    .onTapGesture {
                        viewModel.selectedSessionId = session.sessionId
                    }
                    .padding(.leading, 8)
            }
        } label: {
            HStack {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(group.name)
                    .font(.callout)
                    .fontWeight(.medium)
                Spacer()
                Text("\(group.activeCount)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - View Model

enum SidebarViewMode: String {
    case all
    case byProject
}

struct SidebarSessionInfo {
    let sessionId: String
    let name: String
    let provider: AgentProvider?
    let modelName: String?
    let state: AgentState
}

struct ProjectGroup {
    let name: String
    let sessions: [SidebarSessionInfo]
    var activeCount: Int { sessions.filter { $0.state == .working || $0.state == .needsInput }.count }
}

@Observable
final class SidebarViewModel {
    var searchText: String = ""
    var viewMode: SidebarViewMode = .all
    var selectedSessionId: String?

    private let fleetManager: any FleetManaging

    init(fleetManager: any FleetManaging) {
        self.fleetManager = fleetManager
    }

    var filteredSessions: [SidebarSessionInfo] {
        let sessions = fleetManager.sessions.map { session in
            SidebarSessionInfo(
                sessionId: session.sessionId,
                name: session.agentInfo?.provider.rawValue.capitalized ?? "Session",
                provider: session.agentInfo?.provider,
                modelName: session.agentInfo?.model.name,
                state: session.state
            )
        }

        if searchText.isEmpty { return sessions }
        let query = searchText.lowercased()
        return sessions.filter {
            $0.name.lowercased().contains(query) ||
            ($0.modelName?.lowercased().contains(query) ?? false) ||
            ($0.provider?.rawValue.lowercased().contains(query) ?? false)
        }
    }

    var projectGroups: [ProjectGroup] {
        let byProject = Dictionary(grouping: filteredSessions) { $0.sessionId }
        // Simplified — real impl uses ProjectManager to group
        return [ProjectGroup(name: "Default", sessions: filteredSessions)]
    }
}
