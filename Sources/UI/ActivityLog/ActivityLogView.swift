// MARK: - Activity Log View (Step 6.2)

import SwiftUI
import AgentsBoardCore

struct ActivityLogView: View {
    @Bindable var viewModel: ActivityLogViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            HStack(spacing: 12) {
                Picker("Time", selection: $viewModel.timeFilter) {
                    Text("Last Hour").tag(TimeFilter.lastHour)
                    Text("Today").tag(TimeFilter.today)
                    Text("All").tag(TimeFilter.all)
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 180, maxWidth: 280)

                Spacer()

                Picker("Category", selection: $viewModel.categoryFilter) {
                    Text("All").tag(CategoryFilter.all)
                    Text("Files").tag(CategoryFilter.files)
                    Text("Commands").tag(CategoryFilter.commands)
                    Text("Errors").tag(CategoryFilter.errors)
                    Text("Costs").tag(CategoryFilter.costs)
                }
                .frame(minWidth: 120, maxWidth: 200)
            }
            .padding(12)
            .background(.ultraThinMaterial)

            Divider()

            // Event timeline
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.filteredEvents) { event in
                        ActivityEntryView(event: event)
                    }
                }
                .padding(12)
            }
        }
    }
}

// MARK: - Activity Entry

struct ActivityEntryView: View {
    let event: ActivityEvent

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundStyle(iconColor)
                .frame(width: 20)

            Text(timeString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 50, alignment: .leading)

            Text(String(event.sessionId.prefix(8)))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(minWidth: 60, alignment: .leading)

            Text(event.details)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            if let cost = event.cost {
                Text("$\(cost)")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var iconName: String {
        switch event.eventType {
        case .fileChanged: return "doc.text"
        case .commandRun: return "terminal"
        case .error: return "xmark.circle"
        case .costDelta: return "dollarsign.circle"
        case .approval: return "checkmark.shield"
        case .subAgentSpawn: return "arrow.triangle.branch"
        case .stateChange: return "arrow.triangle.2.circlepath"
        }
    }

    private var iconColor: Color {
        switch event.eventType {
        case .error: return .red
        case .approval: return .yellow
        case .costDelta: return .orange
        default: return .secondary
        }
    }

    private var backgroundColor: Color {
        switch event.eventType {
        case .error: return .red.opacity(0.05)
        case .approval: return .yellow.opacity(0.05)
        default: return .clear
        }
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: event.timestamp)
    }
}

// MARK: - View Model

enum TimeFilter { case lastHour, today, all }
enum CategoryFilter { case all, files, commands, errors, costs }

@Observable
final class ActivityLogViewModel {
    var timeFilter: TimeFilter = .today
    var categoryFilter: CategoryFilter = .all

    private let logger: ActivityLogger

    init(logger: ActivityLogger) {
        self.logger = logger
    }

    var filteredEvents: [ActivityEvent] {
        var events: [ActivityEvent]

        switch timeFilter {
        case .lastHour:
            events = logger.events(since: Date().addingTimeInterval(-3600))
        case .today:
            events = logger.events(since: Calendar.current.startOfDay(for: Date()))
        case .all:
            events = logger.allEvents
        }

        switch categoryFilter {
        case .all: break
        case .files: events = events.filter { $0.eventType == .fileChanged }
        case .commands: events = events.filter { $0.eventType == .commandRun }
        case .errors: events = events.filter { $0.eventType == .error }
        case .costs: events = events.filter { $0.eventType == .costDelta }
        }

        return events.reversed()
    }
}
