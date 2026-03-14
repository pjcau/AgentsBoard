// MARK: - Menu Bar Mode (Step 8.2)
// Compact menu bar extra showing fleet status at a glance.
// Attached to a real NSStatusItem in the macOS status bar.

import SwiftUI
import AppKit
import AgentsBoardCore

// MARK: - NSStatusItem Controller

public final class StatusBarController {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let viewModel: MenuBarViewModel

    public init(viewModel: MenuBarViewModel) {
        self.viewModel = viewModel
    }

    public func setup() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "AgentsBoard")
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.title = "$0.00"
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        self.statusItem = statusItem

        // Update button title with total cost periodically
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.updateButton()
        }
    }

    public func teardown() {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
        popover = nil
    }

    @objc private func togglePopover() {
        if let popover, popover.isShown {
            popover.performClose(nil)
            return
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(viewModel: viewModel)
        )

        if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }

        self.popover = popover
    }

    private func updateButton() {
        statusItem?.button?.title = " \(viewModel.totalCostFormatted)"
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @Bindable var viewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "cpu")
                    .foregroundStyle(Color.accentColor)
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
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Cost per provider
            if !viewModel.providerCosts.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Cost by Provider")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    ForEach(viewModel.providerCosts, id: \.provider) { item in
                        ProviderCostRow(item: item, maxCost: viewModel.maxProviderCost)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()
            }

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
                .frame(maxHeight: 240)
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
        .frame(minWidth: 300, idealWidth: 340, maxWidth: 380)
    }
}

// MARK: - Provider Cost Row

struct ProviderCostRow: View {
    let item: ProviderCostInfo
    let maxCost: Decimal

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: providerIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 14)

            Text(item.provider.displayName)
                .font(.caption)
                .frame(width: 50, alignment: .leading)

            // Cost bar
            GeometryReader { geo in
                let ratio = maxCost > 0 ? CGFloat(truncating: (item.cost / maxCost) as NSDecimalNumber) : 0
                RoundedRectangle(cornerRadius: 2)
                    .fill(providerColor.opacity(0.3))
                    .frame(width: max(2, geo.size.width * min(ratio, 1.0)))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(providerColor)
                            .frame(width: max(2, geo.size.width * min(ratio, 1.0)))
                    }
            }
            .frame(height: 6)

            Text(item.costFormatted)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.orange)
                .frame(width: 52, alignment: .trailing)

            Text("\(item.sessionCount)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 16)
        }
    }

    private var providerIcon: String {
        switch item.provider {
        case .claude: return "brain.head.profile"
        case .codex: return "chevron.left.forwardslash.chevron.right"
        case .aider: return "wrench.and.screwdriver"
        case .gemini: return "sparkles"
        case .custom: return "terminal"
        }
    }

    private var providerColor: Color {
        switch item.provider {
        case .claude: return .orange
        case .codex: return .green
        case .aider: return .blue
        case .gemini: return .purple
        case .custom: return .gray
        }
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
                    .truncationMode(.tail)
                Text(session.lastAction)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
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
    let provider: AgentProvider?
    let state: AgentState
    let cost: String
    let lastAction: String
    var needsAttention: Bool { state == .needsInput || state == .error }
}

struct ProviderCostInfo {
    let provider: AgentProvider
    let cost: Decimal
    let costFormatted: String
    let sessionCount: Int
}

// MARK: - View Model

@Observable
public final class MenuBarViewModel {
    private let fleetManager: any FleetManaging
    private var refreshTimer: Timer?

    public var onOpenMainWindow: (() -> Void)?
    public var onNewSession: (() -> Void)?
    public var onFocusSession: ((String) -> Void)?

    // Cached snapshots for SwiftUI reactivity
    var sessionSnapshot: [MenuBarSessionInfo] = []
    var providerCostSnapshot: [ProviderCostInfo] = []
    var totalCostSnapshot: String = "$0.00"
    var statsSnapshot: FleetStats = .empty

    public init(fleetManager: any FleetManaging) {
        self.fleetManager = fleetManager
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit { refreshTimer?.invalidate() }

    func refresh() {
        statsSnapshot = fleetManager.stats
        totalCostSnapshot = formatCost(statsSnapshot.totalCost)

        sessionSnapshot = fleetManager.sessions
            .filter { $0.state != .inactive }
            .prefix(10)
            .map { session in
                MenuBarSessionInfo(
                    sessionId: session.sessionId,
                    name: session.sessionName,
                    provider: session.agentInfo?.provider,
                    state: session.state,
                    cost: formatCost(session.totalCost),
                    lastAction: ""
                )
            }

        // Aggregate costs per provider
        var providerMap: [AgentProvider: (cost: Decimal, count: Int)] = [:]
        for session in fleetManager.sessions {
            let provider = session.agentInfo?.provider ?? .custom
            let existing = providerMap[provider, default: (cost: 0, count: 0)]
            providerMap[provider] = (cost: existing.cost + session.totalCost, count: existing.count + 1)
        }

        providerCostSnapshot = providerMap
            .sorted { $0.value.cost > $1.value.cost }
            .map { ProviderCostInfo(
                provider: $0.key,
                cost: $0.value.cost,
                costFormatted: formatCost($0.value.cost),
                sessionCount: $0.value.count
            )}
    }

    var activeCount: Int { statsSnapshot.activeSessions }
    var needsInputCount: Int { statsSnapshot.needsInputCount }
    var errorCount: Int { statsSnapshot.errorCount }
    var totalCostFormatted: String { totalCostSnapshot }
    var sessions: [MenuBarSessionInfo] { sessionSnapshot }
    var providerCosts: [ProviderCostInfo] { providerCostSnapshot }
    var maxProviderCost: Decimal { providerCostSnapshot.first?.cost ?? 1 }

    public func openMainWindow() { onOpenMainWindow?() }
    public func newSession() { onNewSession?() }
    public func focusSession(_ id: String) { onFocusSession?(id) }
    public func quit() { NSApplication.shared.terminate(nil) }

    private func formatCost(_ cost: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        return f.string(from: cost as NSDecimalNumber) ?? "$0.00"
    }
}
