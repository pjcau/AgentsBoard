// MARK: - Plan Mode View (Step 10.1)
// Visual plan/task breakdown view for agent work sessions.

import SwiftUI
import AgentsBoardCore

struct PlanModeView: View {
    @Bindable var viewModel: PlanModeViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundStyle(.blue)
                Text(L10n.Plan.title)
                    .font(.headline)

                Spacer()

                Text("\(viewModel.completedCount)/\(viewModel.totalCount) \(L10n.Plan.tasks)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ProgressView(value: viewModel.progress)
                    .frame(width: 100)
            }
            .padding(12)
            .background(.ultraThinMaterial)

            Divider()

            // Task list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.tasks) { task in
                        PlanTaskRow(task: task) {
                            viewModel.toggleTask(task.id)
                        }
                    }
                }
                .padding(12)
            }
        }
    }
}

// MARK: - Plan Task Row

struct PlanTaskRow: View {
    let task: PlanTask
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Status icon
            Button(action: onToggle) {
                Image(systemName: statusIcon)
                    .font(.callout)
                    .foregroundStyle(statusColor)
            }
            .buttonStyle(.plain)

            // Task info
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.callout)
                    .strikethrough(task.status == .completed)
                    .foregroundStyle(task.status == .completed ? .secondary : .primary)

                if let description = task.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Duration
            if let duration = task.estimatedDuration {
                Text(duration)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Priority badge
            if task.priority == .high {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(task.status == .inProgress ? Color.blue.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var statusIcon: String {
        switch task.status {
        case .pending: return "circle"
        case .inProgress: return "circle.dotted"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "forward.circle"
        }
    }

    private var statusColor: Color {
        switch task.status {
        case .pending: return .secondary
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        case .skipped: return .gray
        }
    }
}

// MARK: - Models

struct PlanTask: Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var status: PlanTaskStatus
    var priority: PlanTaskPriority
    var estimatedDuration: String?
    var subtasks: [PlanTask]
}

enum PlanTaskStatus: String, Sendable {
    case pending, inProgress, completed, failed, skipped
}

enum PlanTaskPriority: String, Sendable {
    case low, medium, high
}

// MARK: - View Model

@Observable
final class PlanModeViewModel {
    var tasks: [PlanTask] = []

    var totalCount: Int { tasks.count }
    var completedCount: Int { tasks.filter { $0.status == .completed }.count }
    var progress: Double { totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0 }

    func toggleTask(_ id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        switch tasks[index].status {
        case .pending: tasks[index].status = .inProgress
        case .inProgress: tasks[index].status = .completed
        case .completed: tasks[index].status = .pending
        default: break
        }
    }

    func addTask(title: String, description: String? = nil, priority: PlanTaskPriority = .medium) {
        let task = PlanTask(
            id: UUID(), title: title, description: description,
            status: .pending, priority: priority, estimatedDuration: nil, subtasks: []
        )
        tasks.append(task)
    }

    func parsePlanFromOutput(_ output: String) {
        // Parse numbered task lists from agent output
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Match "1. Task description" or "- Task description"
            if let range = trimmed.range(of: #"^(\d+\.\s+|-\s+)"#, options: .regularExpression) {
                let title = String(trimmed[range.upperBound...])
                addTask(title: title)
            }
        }
    }
}
