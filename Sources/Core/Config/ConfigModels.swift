// MARK: - Config Domain Models

import Foundation

/// Application configuration (merged from defaults + user + project).
public struct AppConfig: Codable, Equatable, Sendable {
    public var theme: String
    public var fontFamily: String
    public var fontSize: CGFloat
    public var notifications: Bool
    public var scrollback: Int
    public var layout: LayoutMode
    public var menuBarMode: Bool
    public var notificationSounds: Bool
    public var terminalNewlineMode: NewlineMode

    public init(theme: String, fontFamily: String, fontSize: CGFloat, notifications: Bool, scrollback: Int, layout: LayoutMode, menuBarMode: Bool, notificationSounds: Bool, terminalNewlineMode: NewlineMode) {
        self.theme = theme
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.notifications = notifications
        self.scrollback = scrollback
        self.layout = layout
        self.menuBarMode = menuBarMode
        self.notificationSounds = notificationSounds
        self.terminalNewlineMode = terminalNewlineMode
    }

    public static let `default` = AppConfig(
        theme: "dark",
        fontFamily: "SF Mono",
        fontSize: 13,
        notifications: true,
        scrollback: 10000,
        layout: .fleet,
        menuBarMode: false,
        notificationSounds: true,
        terminalNewlineMode: .enter
    )
}

/// Layout modes for the main content area.
public enum LayoutMode: String, Codable, Sendable, CaseIterable {
    case single
    case list
    case twoColumn
    case threeColumn
    case fleet
}

/// How Enter key behaves in terminal.
public enum NewlineMode: String, Codable, Sendable {
    case enter
    case shiftEnter
}

/// Theme definition.
public struct Theme: Codable, Equatable, Sendable {
    public let name: String
    public let ansiColors: [String]
    public let foreground: String
    public let background: String
    public let accentColor: String
    public let sidebarBackground: String
    public let cardBackground: String
    public let borderColor: String
    public let textPrimary: String
    public let textSecondary: String

    public init(name: String, ansiColors: [String], foreground: String, background: String, accentColor: String, sidebarBackground: String, cardBackground: String, borderColor: String, textPrimary: String, textSecondary: String) {
        self.name = name
        self.ansiColors = ansiColors
        self.foreground = foreground
        self.background = background
        self.accentColor = accentColor
        self.sidebarBackground = sidebarBackground
        self.cardBackground = cardBackground
        self.borderColor = borderColor
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
    }
}

/// Project-level configuration from agentsboard.yml.
public struct ProjectConfig: Codable, Sendable {
    public let name: String
    public let sessions: [SessionConfig]

    public init(name: String, sessions: [SessionConfig]) {
        self.name = name
        self.sessions = sessions
    }

    public struct SessionConfig: Codable, Sendable {
        public let name: String
        public let command: String
        public let workdir: String?
        public let autoStart: Bool?
        public let restart: RestartPolicy?
        public let env: [String: String]?

        public init(name: String, command: String, workdir: String?, autoStart: Bool?, restart: RestartPolicy?, env: [String: String]?) {
            self.name = name
            self.command = command
            self.workdir = workdir
            self.autoStart = autoStart
            self.restart = restart
            self.env = env
        }
    }

    public enum RestartPolicy: String, Codable, Sendable {
        case never
        case onFailure = "on_failure"
        case always
    }
}
