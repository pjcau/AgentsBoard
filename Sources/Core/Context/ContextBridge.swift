// MARK: - Context Bridge (Step 18.1)
// Cross-agent context sharing via per-project knowledge graph.

import Foundation
import Observation

/// A knowledge entry in the project knowledge graph.
public struct KnowledgeEntry: Identifiable, Codable {
    public let id: UUID
    public let type: KnowledgeType
    public let content: String
    public let sourceSessionId: String
    public let timestamp: Date
    public var relevanceScore: Double

    public init(type: KnowledgeType, content: String, sourceSessionId: String, relevanceScore: Double = 1.0) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.sourceSessionId = sourceSessionId
        self.timestamp = Date()
        self.relevanceScore = relevanceScore
    }
}

public enum KnowledgeType: String, Codable, Sendable {
    case decision       // Architectural decision
    case pattern        // Code pattern discovered
    case bug            // Known bug or issue
    case fileImportant  // Critical file identified
    case convention     // Coding convention
    case dependency     // Dependency relationship
}

/// Per-project knowledge graph.
@Observable
public final class KnowledgeGraph {
    private var entries: [KnowledgeEntry] = []
    private let persistence: any PersistenceProviding
    private let projectId: String
    private let decayFactor: Double = 0.95  // Per-day decay

    init(projectId: String, persistence: any PersistenceProviding) {
        self.projectId = projectId
        self.persistence = persistence
    }

    func add(_ entry: KnowledgeEntry) {
        // Deduplicate similar entries
        if let existingIdx = entries.firstIndex(where: { similar($0, entry) }) {
            entries[existingIdx].relevanceScore = max(entries[existingIdx].relevanceScore, entry.relevanceScore)
        } else {
            entries.append(entry)
        }
        try? persistence.save(entry, in: "knowledge_\(projectId)")
    }

    func query(type: KnowledgeType? = nil, limit: Int = 20) -> [KnowledgeEntry] {
        var result = entries

        // Apply temporal decay
        let now = Date()
        result = result.map { entry in
            var e = entry
            let daysSince = now.timeIntervalSince(entry.timestamp) / 86400
            e.relevanceScore *= pow(decayFactor, daysSince)
            return e
        }

        if let type { result = result.filter { $0.type == type } }

        return result
            .sorted { $0.relevanceScore > $1.relevanceScore }
            .prefix(limit)
            .map { $0 }
    }

    func relevantContext(for query: String, tokenBudget: Int = 2000) -> [KnowledgeEntry] {
        let queryWords = Set(query.lowercased().split(separator: " ").map(String.init))

        return entries
            .map { entry -> (KnowledgeEntry, Double) in
                let contentWords = Set(entry.content.lowercased().split(separator: " ").map(String.init))
                let overlap = Double(queryWords.intersection(contentWords).count)
                let score = overlap * entry.relevanceScore
                return (entry, score)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(10)
            .map(\.0)
    }

    private func similar(_ a: KnowledgeEntry, _ b: KnowledgeEntry) -> Bool {
        a.type == b.type && a.content == b.content
    }
}

/// Extracts knowledge from session events.
struct KnowledgeExtractor {
    func extract(from hookEvent: HookEvent, sessionId: String) -> KnowledgeEntry? {
        switch hookEvent {
        case .fileWrite(let path, _):
            return KnowledgeEntry(type: .fileImportant, content: "Modified: \(path)",
                                sourceSessionId: sessionId, relevanceScore: 0.5)
        case .commandExec(let cmd, let exitCode) where exitCode != 0:
            return KnowledgeEntry(type: .bug, content: "Command failed: \(cmd) (exit \(exitCode))",
                                sourceSessionId: sessionId, relevanceScore: 0.8)
        default:
            return nil
        }
    }
}

/// Injects relevant context into new session prompts.
struct ContextInjector {

    func buildPrefix(from entries: [KnowledgeEntry], tokenBudget: Int = 2000) -> String {
        guard !entries.isEmpty else { return "" }

        var parts: [String] = ["[Project Context from previous sessions]"]
        var tokenCount = 10 // Header

        for entry in entries {
            let line = "- [\(entry.type.rawValue)] \(entry.content)"
            let lineTokens = line.count / 4 // Rough estimate
            if tokenCount + lineTokens > tokenBudget { break }
            parts.append(line)
            tokenCount += lineTokens
        }

        parts.append("[End Context]\n")
        return parts.joined(separator: "\n")
    }
}

/// Main context bridge coordinating extraction, storage, and injection.
@Observable
public final class ContextBridge {
    private var graphs: [String: KnowledgeGraph] = [:]
    private let persistence: any PersistenceProviding
    private let extractor = KnowledgeExtractor()
    private let injector = ContextInjector()

    public init(persistence: any PersistenceProviding) {
        self.persistence = persistence
    }

    public func graph(for projectId: String) -> KnowledgeGraph {
        if let existing = graphs[projectId] { return existing }
        let graph = KnowledgeGraph(projectId: projectId, persistence: persistence)
        graphs[projectId] = graph
        return graph
    }

    public func processEvent(_ event: HookEvent, sessionId: String, projectId: String) {
        if let entry = extractor.extract(from: event, sessionId: sessionId) {
            graph(for: projectId).add(entry)
        }
    }

    public func contextPrefix(for projectId: String, task: String) -> String {
        let entries = graph(for: projectId).relevantContext(for: task)
        return injector.buildPrefix(from: entries)
    }
}
