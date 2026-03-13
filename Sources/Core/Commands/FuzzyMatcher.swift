// MARK: - Fuzzy Matcher (Step 7.1)
// Fast fuzzy string matching for command palette search.

import Foundation

public struct FuzzyMatch: Comparable, Equatable {
    public let command: PaletteCommand
    public let score: Int
    public let matchedRanges: [Range<String.Index>]

    public init(command: PaletteCommand, score: Int, matchedRanges: [Range<String.Index>]) {
        self.command = command
        self.score = score
        self.matchedRanges = matchedRanges
    }

    public static func == (lhs: FuzzyMatch, rhs: FuzzyMatch) -> Bool {
        lhs.command.id == rhs.command.id && lhs.score == rhs.score
    }

    public static func < (lhs: FuzzyMatch, rhs: FuzzyMatch) -> Bool {
        lhs.score > rhs.score // Higher score first
    }
}

public struct FuzzyMatcher {

    public init() {}

    /// Match query against a list of commands, returning sorted results.
    public func match(query: String, commands: [PaletteCommand]) -> [FuzzyMatch] {
        guard !query.isEmpty else {
            return commands.map { FuzzyMatch(command: $0, score: 0, matchedRanges: []) }
        }

        let queryLower = query.lowercased()
        return commands.compactMap { command in
            if let result = fuzzyScore(query: queryLower, target: command.title.lowercased()) {
                return FuzzyMatch(command: command, score: result.score, matchedRanges: result.ranges)
            }
            // Also match subtitle
            if let subtitle = command.subtitle,
               let result = fuzzyScore(query: queryLower, target: subtitle.lowercased()) {
                return FuzzyMatch(command: command, score: result.score / 2, matchedRanges: result.ranges)
            }
            return nil
        }
        .sorted()
    }

    // MARK: - Private

    private struct MatchResult {
        let score: Int
        let ranges: [Range<String.Index>]
    }

    private func fuzzyScore(query: String, target: String) -> MatchResult? {
        var queryIndex = query.startIndex
        var targetIndex = target.startIndex
        var score = 0
        var ranges: [Range<String.Index>] = []
        var consecutive = 0
        var matchStart: String.Index?

        while queryIndex < query.endIndex && targetIndex < target.endIndex {
            if query[queryIndex] == target[targetIndex] {
                score += 1
                consecutive += 1
                score += consecutive // Bonus for consecutive matches

                // Word boundary bonus
                if targetIndex == target.startIndex ||
                   target[target.index(before: targetIndex)] == " " ||
                   target[target.index(before: targetIndex)] == "/" {
                    score += 5
                }

                if matchStart == nil { matchStart = targetIndex }
                queryIndex = query.index(after: queryIndex)
            } else {
                if let start = matchStart {
                    ranges.append(start..<targetIndex)
                    matchStart = nil
                }
                consecutive = 0
            }
            targetIndex = target.index(after: targetIndex)
        }

        // Close any open range
        if let start = matchStart {
            ranges.append(start..<targetIndex)
        }

        guard queryIndex == query.endIndex else { return nil }

        // Bonus for matching near the start
        if let first = ranges.first {
            let distance = target.distance(from: target.startIndex, to: first.lowerBound)
            score += max(0, 10 - distance)
        }

        return MatchResult(score: score, ranges: ranges)
    }
}
