// MARK: - App Menu Commands

import SwiftUI
import AgentsBoardCore
import AgentsBoardUI

struct AgentsBoardCommands: Commands {
    @Bindable var navigationState: NavigationState
    @AppStorage(TerminalFontSize.appStorageKey) private var fontSize: Double = TerminalFontSize.defaultSize

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(L10n.App.newSession) {
                navigationState.showingLauncher = true
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        // "Check for Updates..." in the app menu (after .appInfo = after "About AgentsBoard")
        CommandGroup(after: .appInfo) {
            Button(L10n.App.checkForUpdates) {
                navigationState.showingUpdateSheet = true
            }
        }

        CommandGroup(after: .sidebar) {
            Divider()

            Button(L10n.Fleet.title) {
                navigationState.showingFleetOverview = true
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])

            Button(L10n.ActivityLog.title) {
                navigationState.showingActivityLog = true
            }
            .keyboardShortcut("l", modifiers: .command)

            Button("Command Palette") {
                navigationState.showingCommandPalette.toggle()
            }
            .keyboardShortcut("k", modifiers: .command)
        }

        CommandMenu("Terminal") {
            Button(L10n.Terminal.increaseFont) {
                fontSize = min(fontSize + TerminalFontSize.step, TerminalFontSize.maximum)
            }
            .keyboardShortcut("=", modifiers: .command)

            Button(L10n.Terminal.decreaseFont) {
                fontSize = max(fontSize - TerminalFontSize.step, TerminalFontSize.minimum)
            }
            .keyboardShortcut("-", modifiers: .command)

            Button(L10n.Terminal.resetFont) {
                fontSize = TerminalFontSize.defaultSize
            }
            .keyboardShortcut("0", modifiers: .command)
        }
    }
}
