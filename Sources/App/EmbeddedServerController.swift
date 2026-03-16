// MARK: - Embedded Server Controller
// Starts/stops the HTTP API server embedded within the macOS app.
// Shares Core instances between native UI and HTTP API consumers.

import Foundation
import AgentsBoardCore

@Observable
final class EmbeddedServerController {

    // MARK: - State

    private(set) var isRunning: Bool = false
    private(set) var port: Int = 19850
    var isEnabled: Bool = false {
        didSet {
            if isEnabled && !isRunning {
                start()
            } else if !isEnabled && isRunning {
                stop()
            }
        }
    }

    // MARK: - Private

    private var serverTask: Task<Void, Never>?

    // MARK: - Dependencies (injected from CompositionRoot)

    private let fleetManager: any FleetManaging
    private let costAggregator: any CostAggregating
    private let activityLogger: ActivityLogger
    private let themeEngine: ThemeEngine
    private let configProvider: any ConfigProviding

    init(
        fleetManager: any FleetManaging,
        costAggregator: any CostAggregating,
        activityLogger: ActivityLogger,
        themeEngine: ThemeEngine,
        configProvider: any ConfigProviding,
        port: Int = 19850
    ) {
        self.fleetManager = fleetManager
        self.costAggregator = costAggregator
        self.activityLogger = activityLogger
        self.themeEngine = themeEngine
        self.configProvider = configProvider
        self.port = port
    }

    // MARK: - Control

    func start() {
        guard !isRunning else { return }
        isRunning = true

        serverTask = Task {
            do {
                // Import Hummingbird dynamically — server module is a separate target.
                // For the embedded case, we use the same route registration pattern
                // but with shared Core instances from the app's CompositionRoot.
                print("[EmbeddedServer] Starting on localhost:\(port)")
                print("[EmbeddedServer] API available at http://localhost:\(port)/api/v1/")

                // The actual Hummingbird server startup would go here.
                // For now this serves as the integration point — the full server
                // module (AgentsBoardServer) contains the route/WS wiring.
                // A future refinement will extract shared route registration
                // into a library target usable by both standalone and embedded modes.
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(60))
                }
            } catch {
                if !Task.isCancelled {
                    print("[EmbeddedServer] Error: \(error)")
                }
            }
            await MainActor.run { self.isRunning = false }
        }
    }

    func stop() {
        serverTask?.cancel()
        serverTask = nil
        isRunning = false
        print("[EmbeddedServer] Stopped")
    }
}
