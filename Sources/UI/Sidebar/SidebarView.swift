// MARK: - Sidebar View (Step 5.3)

import SwiftUI
import AgentsBoardCore

struct SidebarView: View {
    @Bindable var viewModel: SidebarViewModel
    var onNewSession: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Search field + Show Archived toggle + New Session button
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search sessions...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                Spacer()
                Button {
                    viewModel.showArchived.toggle()
                } label: {
                    Image(systemName: viewModel.showArchived ? "archivebox.fill" : "archivebox")
                        .font(.body)
                        .foregroundStyle(viewModel.showArchived ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.borderless)
                .help(viewModel.showArchived ? "Hide Archived Sessions" : "Show Archived Sessions")
                Button(action: { onNewSession?() }) {
                    Image(systemName: "plus")
                        .font(.body)
                }
                .buttonStyle(.borderless)
                .help("New Session (Cmd+N)")
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
                LazyVStack(spacing: 6) {
                    switch viewModel.viewMode {
                    case .all:
                        ForEach(viewModel.filteredSessions, id: \.sessionId) { session in
                            SidebarSessionRow(
                                session: session,
                                isSelected: viewModel.selectedSessionId == session.sessionId,
                                onSelect: { viewModel.selectedSessionId = session.sessionId },
                                onEdit: { data in viewModel.onEditSession?(session.sessionId, data) },
                                onArchive: { viewModel.onArchiveSession?(session.sessionId) },
                                onUnarchive: { viewModel.onUnarchiveSession?(session.sessionId) },
                                onDelete: { viewModel.onDeleteSession?(session.sessionId) },
                                onReorder: { draggedId, targetId, above in
                                    viewModel.reorderSession(draggedId: draggedId, targetId: targetId, dropAbove: above)
                                }
                            )
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

// MARK: - Sidebar Session Row (wraps SessionListItem with context menu + edit sheet)

struct SidebarSessionRow: View {
    let session: SidebarSessionInfo
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: (SessionEditData) -> Void
    var onArchive: (() -> Void)?
    var onUnarchive: (() -> Void)?
    var onDelete: (() -> Void)?
    var onReorder: ((_ draggedId: String, _ targetId: String, _ above: Bool) -> Void)?

    @State private var showingEdit = false
    @State private var dropPosition: DropPosition = .none

    var body: some View {
        SessionListItem(session: session, isSelected: isSelected)
            .onTapGesture { onSelect() }
            // Drag source
            .draggable(session.sessionId) {
                // Drag preview
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                    Text(session.name)
                        .font(.callout)
                        .fontWeight(.semibold)
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            // Drop target
            .dropDestination(for: String.self) { items, location in
                guard let draggedId = items.first, draggedId != session.sessionId else { return false }
                onReorder?(draggedId, session.sessionId, dropPosition == .above)
                dropPosition = .none
                return true
            } isTargeted: { targeted in
                if !targeted { dropPosition = .none }
            }
            // Direction indicator based on hover position
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    // Only update when we're in a drag (dropPosition check handled by dropDestination)
                    dropPosition = location.y < 20 ? .above : .below
                case .ended:
                    dropPosition = .none
                }
            }
            // Visual drop indicator
            .overlay(alignment: .top) {
                if dropPosition == .above {
                    DropIndicatorLine()
                }
            }
            .overlay(alignment: .bottom) {
                if dropPosition == .below {
                    DropIndicatorLine()
                }
            }
            .contextMenu {
                Button("Edit Session...") {
                    showingEdit = true
                }
                Divider()
                if session.isArchived {
                    Button("Unarchive Session") {
                        onUnarchive?()
                    }
                } else {
                    Button("Archive Session") {
                        onArchive?()
                    }
                }
                Button("Delete Session...", role: .destructive) {
                    confirmDelete()
                }
                Divider()
                Button("Copy Session ID") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(session.sessionId, forType: .string)
                }
            }
            .sheet(isPresented: $showingEdit) {
                SessionEditView(
                    isPresented: $showingEdit,
                    name: session.name,
                    command: "",
                    workDir: session.projectPath ?? "",
                    gitBranch: session.gitBranch ?? "",
                    provider: session.provider ?? .claude,
                    onSave: onEdit
                )
            }
    }

    // MARK: - Delete Confirmation

    private func confirmDelete() {
        let alert = NSAlert()
        alert.messageText = "Delete \"\(session.name)\"?"
        alert.informativeText = "The session will be removed from AgentsBoard. Files on disk are not affected."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.buttons.first?.hasDestructiveAction = true
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        onDelete?()
    }
}

// MARK: - Drop Indicator

private enum DropPosition {
    case none, above, below
}

private struct DropIndicatorLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(height: 2)
            .padding(.horizontal, 4)
    }
}

// MARK: - Session List Item

struct SessionListItem: View {
    let session: SidebarSessionInfo
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Row 1: State dot + Name + Archive badge or State badge
            HStack(spacing: 6) {
                Circle()
                    .fill(stateColor(session.state))
                    .frame(width: 8, height: 8)

                Text(session.name)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                if session.isArchived {
                    Label("Archived", systemImage: "archivebox")
                        .font(.system(size: 9, weight: .medium))
                        .labelStyle(.iconOnly)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                } else {
                    Text(session.state.rawValue)
                        .font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(stateColor(session.state).opacity(0.15))
                        .foregroundStyle(stateColor(session.state))
                        .clipShape(Capsule())
                }
            }

            // Row 2: Provider pill
            if let provider = session.provider {
                HStack(spacing: 4) {
                    Image(systemName: providerIcon(provider))
                        .font(.system(size: 9))
                    Text(provider.rawValue.capitalized)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.1))
                .foregroundStyle(.secondary)
                .clipShape(Capsule())
            }

            // Row 3: Branch
            if let branch = session.gitBranch {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 9))
                    Text(branch)
                        .font(.caption2)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .foregroundStyle(.cyan)
            }

            // Row 4: Path
            if let path = session.projectPath, !path.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.system(size: 9))
                    Text(Self.shortenPath(path))
                        .font(.caption2)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
                .foregroundStyle(.tertiary)
            }

            // Row 5: Uptime
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 9))
                Text(Self.formatUptime(since: session.startTime))
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
        // Dim archived sessions so they are visually distinct
        .opacity(session.isArchived ? 0.5 : 1.0)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }

    private static func shortenPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private static func formatUptime(since date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let seconds = Int(interval)
        if seconds < 60 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m ago"
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
                SidebarSessionRow(
                    session: session,
                    isSelected: viewModel.selectedSessionId == session.sessionId,
                    onSelect: { viewModel.selectedSessionId = session.sessionId },
                    onEdit: { data in viewModel.onEditSession?(session.sessionId, data) },
                    onArchive: { viewModel.onArchiveSession?(session.sessionId) },
                    onUnarchive: { viewModel.onUnarchiveSession?(session.sessionId) },
                    onDelete: { viewModel.onDeleteSession?(session.sessionId) },
                    onReorder: { draggedId, targetId, above in
                        viewModel.reorderSession(draggedId: draggedId, targetId: targetId, dropAbove: above)
                    }
                )
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
    let startTime: Date
    let gitBranch: String?
    let projectPath: String?
    let isArchived: Bool
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
    var sessionSnapshot: [SidebarSessionInfo] = []
    /// When true, archived sessions are shown (dimmed) alongside active sessions.
    var showArchived: Bool = false

    /// Called when the user edits a session from the sidebar. (sessionId, editData)
    var onEditSession: ((String, SessionEditData) -> Void)?
    /// Called when the user requests to archive a session. (sessionId)
    var onArchiveSession: ((String) -> Void)?
    /// Called when the user requests to unarchive a session. (sessionId)
    var onUnarchiveSession: ((String) -> Void)?
    /// Called when the user confirms deletion of a session. (sessionId)
    var onDeleteSession: ((String) -> Void)?

    private let fleetManager: any FleetManaging
    private var refreshTimer: Timer?

    init(fleetManager: any FleetManaging) {
        self.fleetManager = fleetManager
        refreshSessions()
        // Auto-refresh every 2 seconds to pick up new sessions and update uptime
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshSessions()
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func reorderSession(draggedId: String, targetId: String, dropAbove: Bool) {
        guard draggedId != targetId else { return }
        guard let targetIndex = sessionSnapshot.firstIndex(where: { $0.sessionId == targetId }) else { return }

        let insertIndex = dropAbove ? targetIndex : targetIndex + 1

        // Find the target index in the fleet manager's sessions array
        let fmSessions = fleetManager.sessions
        guard let fmTargetIdx = fmSessions.firstIndex(where: { $0.sessionId == targetId }) else { return }
        let fmInsertIdx = dropAbove ? fmTargetIdx : min(fmTargetIdx + 1, fmSessions.count - 1)

        fleetManager.reorder(sessionId: draggedId, toIndex: fmInsertIdx)

        // Also reorder local snapshot immediately for responsive UI
        if let fromIndex = sessionSnapshot.firstIndex(where: { $0.sessionId == draggedId }) {
            var snapshot = sessionSnapshot
            let item = snapshot.remove(at: fromIndex)
            let adjustedInsert = min(insertIndex > fromIndex ? insertIndex - 1 : insertIndex, snapshot.count)
            snapshot.insert(item, at: adjustedInsert)
            sessionSnapshot = snapshot
        }
    }

    func refreshSessions() {
        sessionSnapshot = fleetManager.sessions.map { session in
            SidebarSessionInfo(
                sessionId: session.sessionId,
                name: session.sessionName,
                provider: session.agentInfo?.provider,
                modelName: session.agentInfo?.model.name,
                state: session.state,
                startTime: session.startTime,
                gitBranch: session.gitBranch,
                projectPath: session.projectPath,
                isArchived: session.isArchived
            )
        }
    }

    var filteredSessions: [SidebarSessionInfo] {
        // Step 1: apply archive visibility filter
        let visibleSessions = showArchived
            ? sessionSnapshot
            : sessionSnapshot.filter { !$0.isArchived }

        // Step 2: apply text search
        guard !searchText.isEmpty else { return visibleSessions }
        let query = searchText.lowercased()
        return visibleSessions.filter {
            $0.name.lowercased().contains(query) ||
            ($0.modelName?.lowercased().contains(query) ?? false) ||
            ($0.provider?.rawValue.lowercased().contains(query) ?? false) ||
            ($0.gitBranch?.lowercased().contains(query) ?? false)
        }
    }

    var projectGroups: [ProjectGroup] {
        // Simplified — real impl uses ProjectManager to group
        return [ProjectGroup(name: "Default", sessions: filteredSessions)]
    }
}
