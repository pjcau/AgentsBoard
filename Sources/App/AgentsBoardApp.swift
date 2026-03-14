// MARK: - AgentsBoard App Entry Point

import SwiftUI
import AppKit
import AgentsBoardCore
import AgentsBoardUI

@main
struct AgentsBoardApp: App {
    @State private var compositionRoot = CompositionRoot()

    init() {
        // The app MUST be launched via the .app bundle (build/AgentsBoard.app)
        // for TextFields to work. Without a bundle identifier, macOS corrupts
        // the responder chain, menus, and window tab management.
        if Bundle.main.bundleIdentifier == nil {
            print("""
            ⚠️  AgentsBoard: No bundle identifier detected!
            ⚠️  TextFields and menus will NOT work correctly.
            ⚠️  Build and run with: ./build.sh && open build/AgentsBoard.app
            """)
        }

        // Set app icon from bundled resource
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = icon
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                fleetManager: compositionRoot.fleetManager,
                commandRegistry: compositionRoot.commandRegistry,
                activityLogger: compositionRoot.activityLogger,
                layoutEngine: compositionRoot.layoutEngine,
                navigationState: compositionRoot.navigationState,
                recorder: compositionRoot.recorder,
                taskRouter: compositionRoot.taskRouter,
                onLaunchEntries: { entries in
                    for entry in entries {
                        compositionRoot.launchSession(
                            command: entry.command,
                            name: entry.name,
                            workdir: entry.workDir.isEmpty ? nil : entry.workDir
                        )
                    }
                },
                onRemix: { config, session in
                    compositionRoot.remixSession(config: config, sourceSession: session)
                }
            )
            .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            AgentsBoardCommands(navigationState: compositionRoot.navigationState)
        }
    }
}
