// MARK: - Command Registry (Step 7.1)
// OCP-compliant command registration system.

import Foundation

/// A command that can be executed from the palette.
public struct PaletteCommand: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let icon: String
    public let category: CommandCategory
    public let shortcut: String?
    public let action: @Sendable () -> Void

    public init(id: String, title: String, subtitle: String? = nil, icon: String = "command",
         category: CommandCategory = .general, shortcut: String? = nil,
         action: @escaping @Sendable () -> Void) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.category = category
        self.shortcut = shortcut
        self.action = action
    }
}

public enum CommandCategory: String, CaseIterable, Sendable {
    case session = "Sessions"
    case navigation = "Navigation"
    case layout = "Layout"
    case theme = "Theme"
    case fleet = "Fleet"
    case general = "General"
}

/// Protocol for command providers (OCP — add new providers without modifying registry).
public protocol CommandProviding: AnyObject {
    var commands: [PaletteCommand] { get }
}

/// Central registry that aggregates commands from multiple providers.
public final class CommandRegistry {

    private var providers: [CommandProviding] = []
    private var staticCommands: [PaletteCommand] = []

    public init() {}

    public func register(provider: CommandProviding) {
        providers.append(provider)
    }

    public func register(command: PaletteCommand) {
        staticCommands.append(command)
    }

    public var allCommands: [PaletteCommand] {
        let dynamic = providers.flatMap { $0.commands }
        return staticCommands + dynamic
    }

    public func commands(in category: CommandCategory) -> [PaletteCommand] {
        allCommands.filter { $0.category == category }
    }
}
