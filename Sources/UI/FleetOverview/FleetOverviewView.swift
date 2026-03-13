// MARK: - Fleet Overview View (Step 6.1)
// Full-screen dashboard showing all agents cross-project.

import SwiftUI
import AgentsBoardCore

struct FleetOverviewView: View {
    @Bindable var viewModel: FleetOverviewViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header with fleet metrics
            FleetHeaderView(stats: viewModel.stats)

            Divider()

            // Filter bar
            FleetFilterBar(
                selectedProviders: $viewModel.selectedProviders,
                selectedStates: $viewModel.selectedStates
            )

            // Agent card grid
            ScrollView {
                LazyVGrid(columns: viewModel.gridColumns, spacing: 12) {
                    ForEach(viewModel.filteredSessions, id: \.sessionId) { session in
                        FleetAgentCard(info: session)
                            .onTapGesture {
                                viewModel.onSessionTap?(session.sessionId)
                            }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Fleet Header

struct FleetHeaderView: View {
    let stats: FleetStats

    var body: some View {
        HStack(spacing: 24) {
            MetricView(label: "Total", value: "\(stats.totalSessions)", icon: "cpu", color: .primary)
            MetricView(label: "Active", value: "\(stats.activeSessions)", icon: "bolt.fill", color: .green)
            MetricView(label: "Needs Input", value: "\(stats.needsInputCount)", icon: "exclamationmark.circle.fill", color: .yellow)
            MetricView(label: "Errors", value: "\(stats.errorCount)", icon: "xmark.circle.fill", color: .red)

            Spacer()

            MetricView(label: "Total Cost", value: formatCost(stats.totalCost), icon: "dollarsign.circle", color: .orange)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func formatCost(_ cost: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: cost as NSDecimalNumber) ?? "$0.00"
    }
}

struct MetricView: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Fleet Agent Card

struct FleetAgentCard: View {
    let info: FleetSessionInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(stateColor)
                    .frame(width: 10, height: 10)
                Text(info.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
                if let model = info.modelName {
                    Text(model)
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }

            HStack {
                Label(info.cost, systemImage: "dollarsign.circle")
                    .font(.caption)
                Spacer()
                Text(info.duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !info.lastAction.isEmpty {
                Text(info.lastAction)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(stateColor.opacity(0.5), lineWidth: 1.5)
        )
    }

    private var stateColor: Color {
        switch info.state {
        case .working: return .green
        case .needsInput: return .yellow
        case .error: return .red
        case .inactive: return .gray
        }
    }
}

// MARK: - Fleet Filter Bar

struct FleetFilterBar: View {
    @Binding var selectedProviders: Set<AgentProvider>
    @Binding var selectedStates: Set<AgentState>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Provider:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(AgentProvider.allCases, id: \.self) { provider in
                    FilterChip(
                        label: provider.rawValue.capitalized,
                        isSelected: selectedProviders.contains(provider)
                    ) {
                        if selectedProviders.contains(provider) {
                            selectedProviders.remove(provider)
                        } else {
                            selectedProviders.insert(provider)
                        }
                    }
                }

                Divider().frame(height: 20)

                Text("State:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach([AgentState.working, .needsInput, .error, .inactive], id: \.self) { state in
                    FilterChip(
                        label: state.rawValue,
                        isSelected: selectedStates.contains(state)
                    ) {
                        if selectedStates.contains(state) {
                            selectedStates.remove(state)
                        } else {
                            selectedStates.insert(state)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(isSelected ? Color.accentColor : Color.gray.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View Model

struct FleetSessionInfo {
    let sessionId: String
    let name: String
    let provider: AgentProvider?
    let modelName: String?
    let state: AgentState
    let cost: String
    let duration: String
    let lastAction: String
}

@Observable
final class FleetOverviewViewModel {
    var selectedProviders: Set<AgentProvider> = []
    var selectedStates: Set<AgentState> = []
    var onSessionTap: ((String) -> Void)?

    private let fleetManager: any FleetManaging

    init(fleetManager: any FleetManaging) {
        self.fleetManager = fleetManager
    }

    var stats: FleetStats { fleetManager.stats }

    var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 12)]
    }

    var filteredSessions: [FleetSessionInfo] {
        let all = fleetManager.sessions.map { session in
            FleetSessionInfo(
                sessionId: session.sessionId,
                name: session.agentInfo?.provider.rawValue.capitalized ?? "Session",
                provider: session.agentInfo?.provider,
                modelName: session.agentInfo?.model.name,
                state: session.state,
                cost: formatCost(session.totalCost),
                duration: formatDuration(since: session.startTime),
                lastAction: ""
            )
        }

        return all.filter { info in
            if !selectedProviders.isEmpty, let p = info.provider, !selectedProviders.contains(p) { return false }
            if !selectedStates.isEmpty, !selectedStates.contains(info.state) { return false }
            return true
        }
    }

    private func formatCost(_ cost: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: cost as NSDecimalNumber) ?? "$0.00"
    }

    private func formatDuration(since date: Date) -> String {
        let m = Int(Date().timeIntervalSince(date) / 60)
        return m < 60 ? "\(m)m" : "\(m/60)h \(m%60)m"
    }
}
