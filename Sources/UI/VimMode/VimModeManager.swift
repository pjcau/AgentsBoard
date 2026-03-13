// MARK: - Vim Mode Manager (Step 7.2)
// Optional vim-style navigation for power users.

import Observation
import AgentsBoardCore

enum VimMode: String, Sendable {
    case normal
    case insert
    case visual
    case command
}

@Observable
final class VimModeManager {

    var isEnabled: Bool = false
    private(set) var mode: VimMode = .normal
    private(set) var pendingKeys: String = ""

    func handleKey(_ char: Character) -> VimAction? {
        guard isEnabled else { return nil }

        switch mode {
        case .normal:
            return handleNormal(char)
        case .insert:
            return handleInsert(char)
        case .visual:
            return handleVisual(char)
        case .command:
            return handleCommand(char)
        }
    }

    func setMode(_ newMode: VimMode) {
        mode = newMode
        pendingKeys = ""
    }

    // MARK: - Normal Mode

    private func handleNormal(_ char: Character) -> VimAction? {
        pendingKeys.append(char)

        let action: VimAction?
        switch pendingKeys {
        case "j": action = .moveDown
        case "k": action = .moveUp
        case "h": action = .moveLeft
        case "l": action = .moveRight
        case "i":
            mode = .insert
            action = .enterInsert
        case "v":
            mode = .visual
            action = .enterVisual
        case ":":
            mode = .command
            action = .enterCommand
        case "G": action = .goToEnd
        case "gg":
            action = .goToStart
            pendingKeys = ""
            return action
        case "g":
            return nil // Wait for second key
        case "/": action = .search
        case "n": action = .nextMatch
        case "N": action = .previousMatch
        case "q": action = .quit
        default:
            pendingKeys = ""
            return nil
        }

        if action != nil { pendingKeys = "" }
        return action
    }

    // MARK: - Insert Mode

    private func handleInsert(_ char: Character) -> VimAction? {
        if char == "\u{1b}" { // Escape
            mode = .normal
            return .exitInsert
        }
        return .passthrough(char)
    }

    // MARK: - Visual Mode

    private func handleVisual(_ char: Character) -> VimAction? {
        switch char {
        case "\u{1b}":
            mode = .normal
            return .exitVisual
        case "j": return .selectDown
        case "k": return .selectUp
        case "y":
            mode = .normal
            return .yank
        default: return nil
        }
    }

    // MARK: - Command Mode

    private func handleCommand(_ char: Character) -> VimAction? {
        if char == "\u{1b}" {
            mode = .normal
            pendingKeys = ""
            return .exitCommand
        }
        if char == "\r" || char == "\n" {
            let cmd = pendingKeys
            mode = .normal
            pendingKeys = ""
            return .executeCommand(cmd)
        }
        pendingKeys.append(char)
        return nil
    }
}

/// Actions that vim key handling can produce.
enum VimAction: Sendable {
    case moveUp, moveDown, moveLeft, moveRight
    case goToStart, goToEnd
    case enterInsert, exitInsert
    case enterVisual, exitVisual, selectUp, selectDown, yank
    case enterCommand, exitCommand, executeCommand(String)
    case search, nextMatch, previousMatch
    case passthrough(Character)
    case quit
}
