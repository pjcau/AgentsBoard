// MARK: - App Menu Commands

import SwiftUI
import AgentsBoardCore
import AgentsBoardUI

struct AgentsBoardCommands: Commands {
    @Bindable var navigationState: NavigationState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Session") {
                navigationState.showingLauncher = true
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(after: .sidebar) {
            Divider()

            Button("Fleet Overview") {
                navigationState.showingFleetOverview = true
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])

            Button("Activity Log") {
                navigationState.showingActivityLog = true
            }
            .keyboardShortcut("l", modifiers: .command)

            Button("Command Palette") {
                navigationState.showingCommandPalette.toggle()
            }
            .keyboardShortcut("k", modifiers: .command)
        }
    }
}
