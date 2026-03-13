// MARK: - Session Card View (Step 5.2)

import SwiftUI
import AgentsBoardCore

struct SessionCardView: View {
    let viewModel: SessionCardViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            SessionCardHeader(
                name: viewModel.name,
                provider: viewModel.provider,
                modelName: viewModel.modelName,
                state: viewModel.state
            )

            // Terminal area (placeholder — Step 2.3 TerminalView replaces this)
            Rectangle()
                .fill(Color.black)
                .overlay(
                    Text(viewModel.lastOutput)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(8),
                    alignment: .topLeading
                )

            // Footer
            SessionCardFooter(
                cost: viewModel.cost,
                duration: viewModel.duration,
                lastAction: viewModel.lastAction
            )
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(viewModel.borderColor, lineWidth: 2)
        )
        .contextMenu {
            SessionContextMenu(sessionId: viewModel.sessionId)
        }
    }
}

// MARK: - Header

struct SessionCardHeader: View {
    let name: String
    let provider: AgentProvider?
    let modelName: String?
    let state: AgentState

    var body: some View {
        HStack(spacing: 8) {
            // State indicator dot
            Circle()
                .fill(stateColor)
                .frame(width: 10, height: 10)

            // Provider icon
            Image(systemName: providerIcon)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Session name
            Text(name)
                .font(.headline)
                .lineLimit(1)

            Spacer()

            // Model badge
            if let model = modelName {
                Text(model)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }

            // State label
            Text(state.rawValue)
                .font(.caption2)
                .foregroundStyle(stateColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var stateColor: Color {
        switch state {
        case .working: return .green
        case .needsInput: return .yellow
        case .error: return .red
        case .inactive: return .gray
        }
    }

    private var providerIcon: String {
        switch provider {
        case .claude: return "brain.head.profile"
        case .codex: return "chevron.left.forwardslash.chevron.right"
        case .aider: return "wrench.and.screwdriver"
        case .gemini: return "sparkles"
        case .custom, .none: return "terminal"
        }
    }
}

// MARK: - Footer

struct SessionCardFooter: View {
    let cost: String
    let duration: String
    let lastAction: String

    var body: some View {
        HStack {
            Label(cost, systemImage: "dollarsign.circle")
                .font(.caption)
            Spacer()
            Text(duration)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(lastAction)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Context Menu

struct SessionContextMenu: View {
    let sessionId: String

    var body: some View {
        Button("Rename") { /* Step 5.2 */ }
        Button("Kill Session") { /* Step 5.2 */ }
        Button("Restart") { /* Step 5.2 */ }
        Divider()
        Button("Remix to Worktree") { /* Step 14.2 */ }
        Button("Start Recording") { /* Step 15.1 */ }
        Divider()
        Button("Copy Session ID") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(sessionId, forType: .string)
        }
    }
}

// MARK: - View Model

@Observable
final class SessionCardViewModel {
    let sessionId: String
    var name: String
    var provider: AgentProvider?
    var modelName: String?
    var state: AgentState = .inactive
    var cost: String = "$0.00"
    var duration: String = "0m"
    var lastAction: String = ""
    var lastOutput: String = ""

    var borderColor: Color {
        switch state {
        case .working: return .green.opacity(0.6)
        case .needsInput: return .yellow.opacity(0.8)
        case .error: return .red.opacity(0.7)
        case .inactive: return .gray.opacity(0.3)
        }
    }

    init(session: any AgentSessionRepresentable) {
        self.sessionId = session.sessionId
        self.name = session.agentInfo?.provider.rawValue.capitalized ?? "Session"
        self.provider = session.agentInfo?.provider
        self.modelName = session.agentInfo?.model.name
        self.state = session.state
        self.cost = Self.formatCost(session.totalCost)
        self.duration = Self.formatDuration(since: session.startTime)
    }

    init(id: String = UUID().uuidString, name: String = "Session") {
        self.sessionId = id
        self.name = name
    }

    private static func formatCost(_ cost: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: cost as NSDecimalNumber) ?? "$0.00"
    }

    private static func formatDuration(since date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}
