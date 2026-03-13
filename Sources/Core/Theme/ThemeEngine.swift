// MARK: - Theme Engine (Step 8.1)
// Hot-reloadable theme system with ANSI-256 + TrueColor support.

import AppKit
import Observation

/// Full terminal theme definition.
public struct TerminalTheme: Codable, Sendable {
    public let name: String
    public let author: String?
    public let background: ThemeColor
    public let foreground: ThemeColor
    public let cursor: ThemeColor
    public let selection: ThemeColor
    public let ansi: ANSIColors

    public init(name: String, author: String?, background: ThemeColor, foreground: ThemeColor, cursor: ThemeColor, selection: ThemeColor, ansi: ANSIColors) {
        self.name = name
        self.author = author
        self.background = background
        self.foreground = foreground
        self.cursor = cursor
        self.selection = selection
        self.ansi = ansi
    }

    public struct ANSIColors: Codable, Sendable {
        public let black: ThemeColor
        public let red: ThemeColor
        public let green: ThemeColor
        public let yellow: ThemeColor
        public let blue: ThemeColor
        public let magenta: ThemeColor
        public let cyan: ThemeColor
        public let white: ThemeColor
        public let brightBlack: ThemeColor
        public let brightRed: ThemeColor
        public let brightGreen: ThemeColor
        public let brightYellow: ThemeColor
        public let brightBlue: ThemeColor
        public let brightMagenta: ThemeColor
        public let brightCyan: ThemeColor
        public let brightWhite: ThemeColor

        public init(black: ThemeColor, red: ThemeColor, green: ThemeColor, yellow: ThemeColor, blue: ThemeColor, magenta: ThemeColor, cyan: ThemeColor, white: ThemeColor, brightBlack: ThemeColor, brightRed: ThemeColor, brightGreen: ThemeColor, brightYellow: ThemeColor, brightBlue: ThemeColor, brightMagenta: ThemeColor, brightCyan: ThemeColor, brightWhite: ThemeColor) {
            self.black = black; self.red = red; self.green = green; self.yellow = yellow
            self.blue = blue; self.magenta = magenta; self.cyan = cyan; self.white = white
            self.brightBlack = brightBlack; self.brightRed = brightRed; self.brightGreen = brightGreen
            self.brightYellow = brightYellow; self.brightBlue = brightBlue; self.brightMagenta = brightMagenta
            self.brightCyan = brightCyan; self.brightWhite = brightWhite
        }

        public var asArray: [ThemeColor] {
            [black, red, green, yellow, blue, magenta, cyan, white,
             brightBlack, brightRed, brightGreen, brightYellow,
             brightBlue, brightMagenta, brightCyan, brightWhite]
        }
    }
}

/// Color representation supporting hex strings.
public struct ThemeColor: Codable, Sendable, Equatable {
    public let r: Double
    public let g: Double
    public let b: Double
    public let a: Double

    public init(r: Double, g: Double, b: Double, a: Double = 1.0) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.r = Double((rgb >> 16) & 0xFF) / 255.0
        self.g = Double((rgb >> 8) & 0xFF) / 255.0
        self.b = Double(rgb & 0xFF) / 255.0
        self.a = 1.0
    }

    public var nsColor: NSColor {
        NSColor(red: r, green: g, blue: b, alpha: a)
    }

    public var simd4: SIMD4<Float> {
        SIMD4(Float(r), Float(g), Float(b), Float(a))
    }
}

/// Built-in themes.
public enum BuiltInTheme: String, CaseIterable, Sendable {
    case dark
    case light
    case solarizedDark
    case monokai
    case nord

    public var theme: TerminalTheme {
        switch self {
        case .dark: return Self.makeDark()
        case .light: return Self.makeLight()
        case .solarizedDark: return Self.makeSolarizedDark()
        case .monokai: return Self.makeMonokai()
        case .nord: return Self.makeNord()
        }
    }

    private static func makeDark() -> TerminalTheme {
        TerminalTheme(
            name: "Dark", author: "AgentsBoard",
            background: ThemeColor(hex: "#1E1E2E"),
            foreground: ThemeColor(hex: "#CDD6F4"),
            cursor: ThemeColor(hex: "#F5E0DC"),
            selection: ThemeColor(hex: "#585B70"),
            ansi: .init(
                black: ThemeColor(hex: "#45475A"), red: ThemeColor(hex: "#F38BA8"),
                green: ThemeColor(hex: "#A6E3A1"), yellow: ThemeColor(hex: "#F9E2AF"),
                blue: ThemeColor(hex: "#89B4FA"), magenta: ThemeColor(hex: "#F5C2E7"),
                cyan: ThemeColor(hex: "#94E2D5"), white: ThemeColor(hex: "#BAC2DE"),
                brightBlack: ThemeColor(hex: "#585B70"), brightRed: ThemeColor(hex: "#F38BA8"),
                brightGreen: ThemeColor(hex: "#A6E3A1"), brightYellow: ThemeColor(hex: "#F9E2AF"),
                brightBlue: ThemeColor(hex: "#89B4FA"), brightMagenta: ThemeColor(hex: "#F5C2E7"),
                brightCyan: ThemeColor(hex: "#94E2D5"), brightWhite: ThemeColor(hex: "#A6ADC8")
            )
        )
    }

    private static func makeLight() -> TerminalTheme {
        TerminalTheme(
            name: "Light", author: "AgentsBoard",
            background: ThemeColor(hex: "#EFF1F5"),
            foreground: ThemeColor(hex: "#4C4F69"),
            cursor: ThemeColor(hex: "#DC8A78"),
            selection: ThemeColor(hex: "#ACB0BE"),
            ansi: .init(
                black: ThemeColor(hex: "#5C5F77"), red: ThemeColor(hex: "#D20F39"),
                green: ThemeColor(hex: "#40A02B"), yellow: ThemeColor(hex: "#DF8E1D"),
                blue: ThemeColor(hex: "#1E66F5"), magenta: ThemeColor(hex: "#EA76CB"),
                cyan: ThemeColor(hex: "#179299"), white: ThemeColor(hex: "#ACB0BE"),
                brightBlack: ThemeColor(hex: "#6C6F85"), brightRed: ThemeColor(hex: "#D20F39"),
                brightGreen: ThemeColor(hex: "#40A02B"), brightYellow: ThemeColor(hex: "#DF8E1D"),
                brightBlue: ThemeColor(hex: "#1E66F5"), brightMagenta: ThemeColor(hex: "#EA76CB"),
                brightCyan: ThemeColor(hex: "#179299"), brightWhite: ThemeColor(hex: "#BCC0CC")
            )
        )
    }

    private static func makeSolarizedDark() -> TerminalTheme {
        TerminalTheme(
            name: "Solarized Dark", author: "Ethan Schoonover",
            background: ThemeColor(hex: "#002B36"),
            foreground: ThemeColor(hex: "#839496"),
            cursor: ThemeColor(hex: "#93A1A1"),
            selection: ThemeColor(hex: "#073642"),
            ansi: .init(
                black: ThemeColor(hex: "#073642"), red: ThemeColor(hex: "#DC322F"),
                green: ThemeColor(hex: "#859900"), yellow: ThemeColor(hex: "#B58900"),
                blue: ThemeColor(hex: "#268BD2"), magenta: ThemeColor(hex: "#D33682"),
                cyan: ThemeColor(hex: "#2AA198"), white: ThemeColor(hex: "#EEE8D5"),
                brightBlack: ThemeColor(hex: "#002B36"), brightRed: ThemeColor(hex: "#CB4B16"),
                brightGreen: ThemeColor(hex: "#586E75"), brightYellow: ThemeColor(hex: "#657B83"),
                brightBlue: ThemeColor(hex: "#839496"), brightMagenta: ThemeColor(hex: "#6C71C4"),
                brightCyan: ThemeColor(hex: "#93A1A1"), brightWhite: ThemeColor(hex: "#FDF6E3")
            )
        )
    }

    private static func makeMonokai() -> TerminalTheme {
        TerminalTheme(
            name: "Monokai", author: "Wimer Hazenberg",
            background: ThemeColor(hex: "#272822"),
            foreground: ThemeColor(hex: "#F8F8F2"),
            cursor: ThemeColor(hex: "#F8F8F0"),
            selection: ThemeColor(hex: "#49483E"),
            ansi: .init(
                black: ThemeColor(hex: "#272822"), red: ThemeColor(hex: "#F92672"),
                green: ThemeColor(hex: "#A6E22E"), yellow: ThemeColor(hex: "#F4BF75"),
                blue: ThemeColor(hex: "#66D9EF"), magenta: ThemeColor(hex: "#AE81FF"),
                cyan: ThemeColor(hex: "#A1EFE4"), white: ThemeColor(hex: "#F8F8F2"),
                brightBlack: ThemeColor(hex: "#75715E"), brightRed: ThemeColor(hex: "#F92672"),
                brightGreen: ThemeColor(hex: "#A6E22E"), brightYellow: ThemeColor(hex: "#F4BF75"),
                brightBlue: ThemeColor(hex: "#66D9EF"), brightMagenta: ThemeColor(hex: "#AE81FF"),
                brightCyan: ThemeColor(hex: "#A1EFE4"), brightWhite: ThemeColor(hex: "#F9F8F5")
            )
        )
    }

    private static func makeNord() -> TerminalTheme {
        TerminalTheme(
            name: "Nord", author: "Arctic Ice Studio",
            background: ThemeColor(hex: "#2E3440"),
            foreground: ThemeColor(hex: "#D8DEE9"),
            cursor: ThemeColor(hex: "#D8DEE9"),
            selection: ThemeColor(hex: "#434C5E"),
            ansi: .init(
                black: ThemeColor(hex: "#3B4252"), red: ThemeColor(hex: "#BF616A"),
                green: ThemeColor(hex: "#A3BE8C"), yellow: ThemeColor(hex: "#EBCB8B"),
                blue: ThemeColor(hex: "#81A1C1"), magenta: ThemeColor(hex: "#B48EAD"),
                cyan: ThemeColor(hex: "#88C0D0"), white: ThemeColor(hex: "#E5E9F0"),
                brightBlack: ThemeColor(hex: "#4C566A"), brightRed: ThemeColor(hex: "#BF616A"),
                brightGreen: ThemeColor(hex: "#A3BE8C"), brightYellow: ThemeColor(hex: "#EBCB8B"),
                brightBlue: ThemeColor(hex: "#81A1C1"), brightMagenta: ThemeColor(hex: "#B48EAD"),
                brightCyan: ThemeColor(hex: "#8FBCBB"), brightWhite: ThemeColor(hex: "#ECEFF4")
            )
        )
    }
}

/// Manages active theme with hot-reload support.
@Observable
public final class ThemeEngine: ThemeProviding {

    public private(set) var activeTheme: TerminalTheme
    public private(set) var allThemes: [TerminalTheme]
    public var onThemeChange: ((Theme) -> Void)?

    public init() {
        let defaultTheme = BuiltInTheme.dark.theme
        self.activeTheme = defaultTheme
        self.allThemes = BuiltInTheme.allCases.map(\.theme)
    }

    public var currentTheme: Theme {
        Theme(
            name: activeTheme.name,
            ansiColors: activeTheme.ansi.asArray.map(\.hex),
            foreground: activeTheme.foreground.hex,
            background: activeTheme.background.hex,
            accentColor: activeTheme.cursor.hex,
            sidebarBackground: activeTheme.background.hex,
            cardBackground: activeTheme.selection.hex,
            borderColor: activeTheme.selection.hex,
            textPrimary: activeTheme.foreground.hex,
            textSecondary: activeTheme.foreground.hex
        )
    }

    public var availableThemes: [String] {
        allThemes.map(\.name)
    }

    public func loadTheme(named name: String) throws {
        if let theme = allThemes.first(where: { $0.name == name }) {
            activeTheme = theme
            onThemeChange?(currentTheme)
        }
    }

    public func addCustomTheme(_ theme: TerminalTheme) {
        allThemes.append(theme)
    }
}

// MARK: - ThemeColor hex output

private extension ThemeColor {
    var hex: String {
        String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
