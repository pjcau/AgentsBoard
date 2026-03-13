// MARK: - App Menu Commands

import SwiftUI
import AgentsBoardCore
import AgentsBoardUI

struct AgentsBoardCommands: Commands {
    let compositionRoot: CompositionRoot

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Session") {
                // TODO: Step 14.1
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(after: .sidebar) {
            Button("Toggle Sidebar") {
                // TODO: Step 5.3
            }
            .keyboardShortcut("b", modifiers: .command)

            Divider()

            Button("Fleet Overview") {
                // TODO: Step 6.1
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])

            Button("Activity Log") {
                // TODO: Step 6.2
            }
            .keyboardShortcut("l", modifiers: .command)

            Button("Command Palette") {
                // TODO: Step 7.1
            }
            .keyboardShortcut("k", modifiers: .command)
        }
    }
}
