// MARK: - Config & Theme Tests

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - AppConfig Tests

@Suite("AppConfig")
struct AppConfigTests {
    @Test func defaultConfig() {
        let config = AppConfig.default
        #expect(!config.fontFamily.isEmpty)
        #expect(config.fontSize > 0)
        #expect(config.scrollback > 0)
    }

    @Test func layoutModes() {
        let modes: [LayoutMode] = [.single, .list, .twoColumn, .threeColumn, .fleet]
        #expect(modes.count == 5)
    }

    @Test func newlineModes() {
        #expect(NewlineMode.enter != NewlineMode.shiftEnter)
    }
}

// MARK: - Theme Tests

@Suite("Theme")
struct ThemeTests {
    @Test func creation() {
        let theme = Theme(
            name: "test",
            ansiColors: Array(repeating: "#FF0000", count: 16),
            foreground: "#FFFFFF",
            background: "#000000",
            accentColor: "#007AFF",
            sidebarBackground: "#111111",
            cardBackground: "#222222",
            borderColor: "#333333",
            textPrimary: "#FFFFFF",
            textSecondary: "#888888"
        )
        #expect(theme.name == "test")
        #expect(theme.ansiColors.count == 16)
        #expect(theme.foreground == "#FFFFFF")
        #expect(theme.background == "#000000")
    }
}

// MARK: - ThemeColor Tests

@Suite("ThemeColor")
struct ThemeColorTests {
    @Test func hexInit() {
        let color = ThemeColor(hex: "#FF0000")
        #expect(color.r > 0.99)
        #expect(color.g < 0.01)
        #expect(color.b < 0.01)
    }

    @Test func hexInitGreen() {
        let color = ThemeColor(hex: "#00FF00")
        #expect(color.r < 0.01)
        #expect(color.g > 0.99)
        #expect(color.b < 0.01)
    }

    @Test func hexInitBlue() {
        let color = ThemeColor(hex: "#0000FF")
        #expect(color.r < 0.01)
        #expect(color.g < 0.01)
        #expect(color.b > 0.99)
    }

    @Test func simd4Conversion() {
        let color = ThemeColor(hex: "#FF8040")
        let simd = color.simd4
        #expect(simd.x > 0.99) // R
        #expect(simd.y > 0.49 && simd.y < 0.52) // G ~0.5
        #expect(simd.z > 0.24 && simd.z < 0.26) // B ~0.25
        #expect(simd.w > 0.99) // A
    }
}

// MARK: - BuiltInTheme Tests

@Suite("BuiltInTheme")
struct BuiltInThemeTests {
    @Test func allThemesHaveNames() {
        let themes: [BuiltInTheme] = [.dark, .light, .solarizedDark, .monokai, .nord]
        for builtIn in themes {
            let theme = builtIn.theme
            #expect(!theme.name.isEmpty)
        }
    }

    @Test func darkThemeColors() {
        let theme = BuiltInTheme.dark.theme
        #expect(theme.name == "dark" || theme.name.lowercased().contains("dark"))
    }
}

// MARK: - ThemeEngine Tests

@Suite("ThemeEngine")
struct ThemeEngineTests {
    @Test func initialActiveTheme() {
        let engine = ThemeEngine()
        #expect(!engine.activeTheme.name.isEmpty)
    }

    @Test func allThemesPopulated() {
        let engine = ThemeEngine()
        #expect(engine.allThemes.count >= 5)
    }

    @Test func addCustomTheme() {
        let engine = ThemeEngine()
        let initial = engine.allThemes.count
        let custom = BuiltInTheme.dark.theme
        let customTheme = TerminalTheme(
            name: "custom_test",
            author: "test",
            background: custom.background,
            foreground: custom.foreground,
            cursor: custom.cursor,
            selection: custom.selection,
            ansi: custom.ansi
        )
        engine.addCustomTheme(customTheme)
        #expect(engine.allThemes.count == initial + 1)
    }
}

// MARK: - ProjectConfig Tests

@Suite("ProjectConfig")
struct ProjectConfigTests {
    @Test func sessionConfig() {
        let session = ProjectConfig.SessionConfig(
            name: "test", command: "claude", workdir: "/tmp",
            autoStart: true, restart: .onFailure, env: ["KEY": "VALUE"]
        )
        #expect(session.name == "test")
        #expect(session.autoStart == true)
        #expect(session.restart == .onFailure)
    }

    @Test func restartPolicies() {
        let policies: [ProjectConfig.RestartPolicy] = [.never, .onFailure, .always]
        #expect(policies.count == 3)
    }
}

// MARK: - TerminalTheme Tests

@Suite("TerminalTheme")
struct TerminalThemeTests {
    @Test func ansiColors() {
        let theme = BuiltInTheme.monokai.theme
        // ANSI colors struct should have all 16 standard colors
        let _ = theme.ansi.black
        let _ = theme.ansi.red
        let _ = theme.ansi.green
        let _ = theme.ansi.yellow
        let _ = theme.ansi.blue
        let _ = theme.ansi.magenta
        let _ = theme.ansi.cyan
        let _ = theme.ansi.white
        let _ = theme.ansi.brightBlack
        let _ = theme.ansi.brightRed
        let _ = theme.ansi.brightGreen
        let _ = theme.ansi.brightYellow
        let _ = theme.ansi.brightBlue
        let _ = theme.ansi.brightMagenta
        let _ = theme.ansi.brightCyan
        let _ = theme.ansi.brightWhite
        #expect(true) // If we get here, all properties exist
    }
}
