// MARK: - AgentsBoard App Entry Point

import SwiftUI
import AgentsBoardCore
import AgentsBoardUI

@main
struct AgentsBoardApp: App {
    @State private var compositionRoot = CompositionRoot()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(compositionRoot)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            AgentsBoardCommands(compositionRoot: compositionRoot)
        }
    }
}
