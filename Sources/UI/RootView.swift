// MARK: - Root View (wires all UI components)

import SwiftUI
import AppKit
import AgentsBoardCore

/// Observable container for navigation state, injected from App target.
@Observable
public final class NavigationState {
    public var showingLauncher = false
    public var showingFleetOverview = false
    public var showingActivityLog = false
    public var showingCommandPalette = false
    public var selectedSessionId: String?
    public var layoutMode: LayoutMode = .fleet

    public init() {}
}

/// Wraps FleetManager to provide observable session list for SwiftUI.
@Observable
public final class FleetBridge {
    public var sessions: [any AgentSessionRepresentable] = []

    private let fleetManager: any FleetManaging

    public init(fleetManager: any FleetManaging) {
        self.fleetManager = fleetManager
        refresh()
        // Listen for fleet changes
        if let fm = fleetManager as? FleetManager {
            fm.onFleetChange = { [weak self] in
                self?.refresh()
            }
        }
    }

    public func refresh() {
        sessions = fleetManager.sessions
    }
}

public struct RootView: View {
    private let layoutEngine: LayoutEngine
    private let onLaunchEntries: ([LaunchEntry]) -> Void
    @Bindable private var nav: NavigationState
    @Bindable private var fleet: FleetBridge

    // All ViewModels as @State so they persist across renders
    @State private var sidebarVM: SidebarViewModel
    @State private var fleetOverviewVM: FleetOverviewViewModel
    @State private var activityLogVM: ActivityLogViewModel
    @State private var commandPaletteVM: CommandPaletteViewModel
    @State private var cardViewModels: [String: SessionCardViewModel] = [:]

    // NSPanel-based launcher (bypasses SwiftUI sheet focus issues)
    @State private var launcherPresenter = LauncherPresenter()

    public init(
        fleetManager: any FleetManaging,
        commandRegistry: CommandRegistry,
        activityLogger: ActivityLogger,
        layoutEngine: LayoutEngine,
        navigationState: NavigationState,
        onLaunchEntries: @escaping ([LaunchEntry]) -> Void
    ) {
        self.layoutEngine = layoutEngine
        self.nav = navigationState
        self.onLaunchEntries = onLaunchEntries

        let bridge = FleetBridge(fleetManager: fleetManager)
        self._fleet = Bindable(bridge)

        self._sidebarVM = State(initialValue: SidebarViewModel(fleetManager: fleetManager))
        self._fleetOverviewVM = State(initialValue: FleetOverviewViewModel(fleetManager: fleetManager))
        self._activityLogVM = State(initialValue: ActivityLogViewModel(logger: activityLogger))
        self._commandPaletteVM = State(initialValue: CommandPaletteViewModel(registry: commandRegistry))
    }

    public var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: sidebarVM)
                .frame(minWidth: 180, idealWidth: 220, maxWidth: 320)
        } detail: {
            detailContent
        }
        // Launcher uses NSPanel — no .sheet needed
        .onChange(of: nav.showingLauncher) { _, show in
            if show {
                launcherPresenter.present { entries in
                    onLaunchEntries(entries)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        fleet.refresh()
                    }
                }
                nav.showingLauncher = false
            }
        }
        .sheet(isPresented: $nav.showingFleetOverview) {
            FleetOverviewView(viewModel: fleetOverviewVM)
                .frame(minWidth: 500, idealWidth: 700, minHeight: 400, idealHeight: 500)
        }
        .sheet(isPresented: $nav.showingActivityLog) {
            ActivityLogView(viewModel: activityLogVM)
                .frame(minWidth: 450, idealWidth: 600, minHeight: 300, idealHeight: 400)
        }
        .overlay {
            if nav.showingCommandPalette {
                commandPaletteOverlay
            }
        }
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        if fleet.sessions.isEmpty {
            emptyState
        } else {
            sessionGrid
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("AgentsBoard")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("AI Agent Mission Control")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("No active sessions")
                .font(.body)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
            Button("Launch Session") {
                nav.showingLauncher = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionGrid: some View {
        GeometryReader { geo in
            let sessions = fleet.sessions
            let frames = layoutEngine.computeFrames(
                cardCount: sessions.count,
                in: geo.size,
                mode: nav.layoutMode
            )
            ZStack {
                ForEach(Array(sessions.enumerated()), id: \.element.sessionId) { index, session in
                    if index < frames.count {
                        let frame = frames[index]
                        let vm = viewModel(for: session)
                        SessionCardView(viewModel: vm)
                            .frame(width: frame.rect.width, height: frame.rect.height)
                            .position(x: frame.rect.midX, y: frame.rect.midY)
                            .onTapGesture {
                                nav.selectedSessionId = session.sessionId
                            }
                    }
                }
            }
        }
    }

    /// Returns a cached or new SessionCardViewModel for the given session.
    private func viewModel(for session: any AgentSessionRepresentable) -> SessionCardViewModel {
        if let existing = cardViewModels[session.sessionId] {
            return existing
        }
        let vm = SessionCardViewModel(session: session)
        DispatchQueue.main.async {
            cardViewModels[session.sessionId] = vm
        }
        return vm
    }

    // MARK: - Command Palette Overlay

    private var commandPaletteOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    nav.showingCommandPalette = false
                }
            CommandPaletteView(viewModel: commandPaletteVM)
                .frame(maxWidth: 500, maxHeight: 400)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 20)
        }
    }
}
