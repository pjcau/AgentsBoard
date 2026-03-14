// MARK: - App Menu Commands

import SwiftUI
import AgentsBoardCore
import AgentsBoardUI

struct AgentsBoardCommands: Commands {
    @Bindable var navigationState: NavigationState
    @AppStorage(TerminalFontSize.appStorageKey) private var fontSize: Double = TerminalFontSize.defaultSize

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

        CommandMenu("Terminal") {
            Button("Increase Font Size") {
                fontSize = min(fontSize + TerminalFontSize.step, TerminalFontSize.maximum)
            }
            .keyboardShortcut("=", modifiers: .command)

            Button("Decrease Font Size") {
                fontSize = max(fontSize - TerminalFontSize.step, TerminalFontSize.minimum)
            }
            .keyboardShortcut("-", modifiers: .command)

            Button("Reset Font Size") {
                fontSize = TerminalFontSize.defaultSize
            }
            .keyboardShortcut("0", modifiers: .command)
        }
    }
}
