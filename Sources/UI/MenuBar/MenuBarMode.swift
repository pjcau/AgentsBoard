// MARK: - Menu Bar Mode (Step 8.2)
// Compact menu bar extra showing fleet status at a glance.

import SwiftUI
import AgentsBoardCore

struct MenuBarView: View {
    @Bindable var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AgentsBoard")
                    .font(.headline)
                Spacer()
                Button("Open App") {
                    viewModel.openMainWindow()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
            .padding(12)

            Divider()

            // Quick stats
            HStack(spacing: 16) {
                QuickStat(icon: "bolt.fill", value: "\(viewModel.activeCount)", color: .green)
                QuickStat(icon: "exclamationmark.circle.fill", value: "\(viewModel.needsInputCount)", color: .yellow)
                QuickStat(icon: "xmark.circle.fill", value: "\(viewModel.errorCount)", color: .red)
                Spacer()
                Text(viewModel.totalCostFormatted)
                    .font(.callout)
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Session list
            if viewModel.sessions.isEmpty {
                Text("No active sessions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(20)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(viewModel.sessions, id: \.sessionId) { session in
                            MenuBarSessionRow(session: session)
                                .onTapGesture {
                                    viewModel.focusSession(session.sessionId)
                                }
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 300)
            }

            Divider()

            // Footer actions
            HStack {
                Button("New Session") {
                    viewModel.newSession()
                }
                .font(.caption)
                .buttonStyle(.borderless)
                Spacer()
                Button("Quit") {
                    viewModel.quit()
                }
                .font(.caption)
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
            .padding(8)
        }
        .frame(width: 320)
    }
}

// MARK: - Quick Stat

struct QuickStat: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Session Row

struct MenuBarSessionRow: View {
    let session: MenuBarSessionInfo

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(session.name)
                    .font(.caption)
                    .lineLimit(1)
                Text(session.lastAction)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text(session.cost)
                .font(.caption2)
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(session.needsAttention ? Color.yellow.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var stateColor: Color {
        switch session.state {
        case .working: return .green
        case .needsInput: return .yellow
        case .error: return .red
        case .inactive: return .gray
        }
    }
}

// MARK: - Data Models

struct MenuBarSessionInfo {
    let sessionId: String
    let name: String
    let state: AgentState
    let cost: String
    let lastAction: String
    var needsAttention: Bool { state == .needsInput || state == .error }
}

// MARK: - View Model

@Observable
final class MenuBarViewModel {
    private let fleetManager: any FleetManaging

    var onOpenMainWindow: (() -> Void)?
    var onNewSession: (() -> Void)?
    var onFocusSession: ((String) -> Void)?

    init(fleetManager: any FleetManaging) {
        self.fleetManager = fleetManager
    }

    var activeCount: Int { fleetManager.stats.activeSessions }
    var needsInputCount: Int { fleetManager.stats.needsInputCount }
    var errorCount: Int { fleetManager.stats.errorCount }

    var totalCostFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: fleetManager.stats.totalCost as NSDecimalNumber) ?? "$0.00"
    }

    var sessions: [MenuBarSessionInfo] {
        fleetManager.sessions
            .filter { $0.state != .inactive }
            .prefix(10)
            .map { session in
                MenuBarSessionInfo(
                    sessionId: session.sessionId,
                    name: session.agentInfo?.provider.rawValue.capitalized ?? "Session",
                    state: session.state,
                    cost: formatCost(session.totalCost),
                    lastAction: ""
                )
            }
    }

    func openMainWindow() { onOpenMainWindow?() }
    func newSession() { onNewSession?() }
    func focusSession(_ id: String) { onFocusSession?(id) }
    func quit() { NSApplication.shared.terminate(nil) }

    private func formatCost(_ cost: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: cost as NSDecimalNumber) ?? "$0.00"
    }
}
