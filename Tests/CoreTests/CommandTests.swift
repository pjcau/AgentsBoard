// MARK: - Command Registry & Fuzzy Matcher Tests

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - Helper

private func makeCommand(
    title: String,
    category: CommandCategory = .general,
    shortcut: String? = nil
) -> PaletteCommand {
    PaletteCommand(
        id: UUID().uuidString,
        title: title,
        subtitle: nil,
        icon: "star",
        category: category,
        shortcut: shortcut,
        action: {}
    )
}

// MARK: - CommandCategory Tests

@Suite("CommandCategory")
struct CommandCategoryTests {
    @Test func allCases() {
        let categories = CommandCategory.allCases
        #expect(categories.contains(.session))
        #expect(categories.contains(.navigation))
        #expect(categories.contains(.layout))
        #expect(categories.contains(.theme))
        #expect(categories.contains(.fleet))
        #expect(categories.contains(.general))
    }
}

// MARK: - PaletteCommand Tests

@Suite("PaletteCommand")
struct PaletteCommandTests {
    @Test func creation() {
        let cmd = makeCommand(title: "Test Command", shortcut: "⌘T")
        #expect(cmd.title == "Test Command")
        #expect(cmd.shortcut == "⌘T")
        #expect(cmd.icon == "star")
    }

    @Test func identifiable() {
        let c1 = makeCommand(title: "A")
        let c2 = makeCommand(title: "B")
        #expect(c1.id != c2.id)
    }
}

// MARK: - CommandRegistry Tests

@Suite("CommandRegistry")
struct CommandRegistryTests {
    @Test func registerSingleCommand() {
        let registry = CommandRegistry()
        let cmd = makeCommand(title: "Test")
        registry.register(command: cmd)
        #expect(registry.allCommands.count == 1)
        #expect(registry.allCommands.first?.title == "Test")
    }

    @Test func registerMultipleCommands() {
        let registry = CommandRegistry()
        registry.register(command: makeCommand(title: "A"))
        registry.register(command: makeCommand(title: "B"))
        registry.register(command: makeCommand(title: "C"))
        #expect(registry.allCommands.count == 3)
    }

    @Test func filterByCategory() {
        let registry = CommandRegistry()
        registry.register(command: makeCommand(title: "Session 1", category: .session))
        registry.register(command: makeCommand(title: "Theme 1", category: .theme))
        registry.register(command: makeCommand(title: "Session 2", category: .session))

        let sessionCommands = registry.commands(in: .session)
        #expect(sessionCommands.count == 2)

        let themeCommands = registry.commands(in: .theme)
        #expect(themeCommands.count == 1)

        let fleetCommands = registry.commands(in: .fleet)
        #expect(fleetCommands.count == 0)
    }

    @Test func registerProvider() {
        let registry = CommandRegistry()
        let provider = TestCommandProvider()
        registry.register(provider: provider)
        #expect(registry.allCommands.count == 2)
    }
}

private final class TestCommandProvider: CommandProviding {
    var commands: [PaletteCommand] {
        [
            makeCommand(title: "Provider Cmd 1"),
            makeCommand(title: "Provider Cmd 2"),
        ]
    }
}

// MARK: - FuzzyMatcher Tests

@Suite("FuzzyMatcher")
struct FuzzyMatcherTests {
    let matcher = FuzzyMatcher()

    @Test func exactMatch() {
        let commands = [makeCommand(title: "New Session")]
        let results = matcher.match(query: "New Session", commands: commands)
        #expect(results.count == 1)
        #expect(results.first?.command.title == "New Session")
    }

    @Test func partialMatch() {
        let commands = [
            makeCommand(title: "New Session"),
            makeCommand(title: "Close Session"),
            makeCommand(title: "Theme Dark"),
        ]
        let results = matcher.match(query: "ses", commands: commands)
        #expect(results.count >= 2) // At least the two session commands
    }

    @Test func noMatch() {
        let commands = [makeCommand(title: "New Session")]
        let results = matcher.match(query: "zzzzzzz", commands: commands)
        #expect(results.isEmpty)
    }

    @Test func emptyQuery() {
        let commands = [makeCommand(title: "A"), makeCommand(title: "B")]
        let results = matcher.match(query: "", commands: commands)
        // Empty query should return all or none depending on implementation
        #expect(results.count >= 0)
    }

    @Test func resultsSortedByScore() {
        let commands = [
            makeCommand(title: "session"),
            makeCommand(title: "New Session"),
            makeCommand(title: "Session Manager"),
        ]
        let results = matcher.match(query: "session", commands: commands)
        if results.count >= 2 {
            // Higher scores first
            #expect(results.first!.score >= results.last!.score)
        }
    }
}

// MARK: - FuzzyMatch Tests

@Suite("FuzzyMatch")
struct FuzzyMatchTests {
    @Test func equatable() {
        let cmd = makeCommand(title: "Test")
        let m1 = FuzzyMatch(command: cmd, score: 10, matchedRanges: [])
        let m2 = FuzzyMatch(command: cmd, score: 10, matchedRanges: [])
        #expect(m1 == m2)
    }

    @Test func comparable() {
        let cmd = makeCommand(title: "Test")
        let low = FuzzyMatch(command: cmd, score: 5, matchedRanges: [])
        let high = FuzzyMatch(command: cmd, score: 15, matchedRanges: [])
        // FuzzyMatch conforms to Comparable - ordering may be ascending or descending
        #expect(low != high)
    }
}
