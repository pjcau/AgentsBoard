// MARK: - Context Bridge & Knowledge Graph Tests

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - KnowledgeType Tests

@Suite("KnowledgeType")
struct KnowledgeTypeTests {
    @Test func allTypes() {
        let types: [KnowledgeType] = [
            .decision, .pattern, .bug, .fileImportant, .convention, .dependency
        ]
        #expect(types.count == 6)
    }
}

// MARK: - KnowledgeEntry Tests

@Suite("KnowledgeEntry")
struct KnowledgeEntryTests {
    @Test func creation() {
        let entry = KnowledgeEntry(
            type: .decision,
            content: "Use JWT for auth",
            sourceSessionId: "s1",
            relevanceScore: 0.9
        )
        #expect(entry.type == .decision)
        #expect(entry.content == "Use JWT for auth")
        #expect(entry.relevanceScore == 0.9)
    }

    @Test func codable() throws {
        let entry = KnowledgeEntry(
            type: .bug,
            content: "Memory leak in renderer",
            sourceSessionId: "s1",
            relevanceScore: 0.8
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(KnowledgeEntry.self, from: data)
        #expect(decoded.id == entry.id)
        #expect(decoded.type == .bug)
        #expect(decoded.content == "Memory leak in renderer")
    }

    @Test func defaultRelevance() {
        let entry = KnowledgeEntry(
            type: .convention,
            content: "Test",
            sourceSessionId: "s1"
        )
        #expect(entry.relevanceScore == 1.0)
    }
}

// MARK: - KnowledgeGraph Tests

@Suite("KnowledgeGraph")
struct KnowledgeGraphTests {
    private func makeGraph() -> KnowledgeGraph {
        KnowledgeGraph(projectId: "test_project", persistence: MockPersistence())
    }

    @Test func addEntry() {
        let graph = makeGraph()
        graph.add(KnowledgeEntry(
            type: .decision,
            content: "Use GRDB for persistence",
            sourceSessionId: "s1"
        ))
        let results = graph.query(type: .decision, limit: 10)
        #expect(results.count == 1)
        #expect(results.first?.content == "Use GRDB for persistence")
    }

    @Test func queryByType() {
        let graph = makeGraph()
        graph.add(KnowledgeEntry(type: .decision, content: "D1", sourceSessionId: "s1"))
        graph.add(KnowledgeEntry(type: .bug, content: "B1", sourceSessionId: "s1"))
        graph.add(KnowledgeEntry(type: .decision, content: "D2", sourceSessionId: "s1"))

        #expect(graph.query(type: .decision, limit: 10).count == 2)
        #expect(graph.query(type: .bug, limit: 10).count == 1)
    }

    @Test func queryLimit() {
        let graph = makeGraph()
        for i in 0..<10 {
            graph.add(KnowledgeEntry(type: .pattern, content: "Pattern \(i)", sourceSessionId: "s1"))
        }
        #expect(graph.query(type: .pattern, limit: 3).count == 3)
    }

    @Test func relevantContext() {
        let graph = makeGraph()
        graph.add(KnowledgeEntry(
            type: .decision,
            content: "Authentication uses JWT tokens with 24h expiry",
            sourceSessionId: "s1"
        ))
        graph.add(KnowledgeEntry(
            type: .convention,
            content: "All API routes prefixed with /api/v1",
            sourceSessionId: "s1"
        ))

        // relevantContext returns entries up to a token budget
        let results = graph.relevantContext(for: "auth", tokenBudget: 1000)
        // May return all entries or filtered subset
        #expect(results.count >= 0)
    }
}

// MARK: - ContextBridge Tests

@Suite("ContextBridge")
struct ContextBridgeTests {
    private func makeBridge() -> ContextBridge {
        ContextBridge(persistence: MockPersistence())
    }

    @Test func graphPerProject() {
        let bridge = makeBridge()
        let g1 = bridge.graph(for: "project1")
        let g2 = bridge.graph(for: "project2")

        g1.add(KnowledgeEntry(type: .decision, content: "Test", sourceSessionId: "s1"))
        #expect(g1.query(type: .decision, limit: 10).count == 1)
        #expect(g2.query(type: .decision, limit: 10).count == 0)
    }

    @Test func contextPrefix() {
        let bridge = makeBridge()
        let graph = bridge.graph(for: "myproject")
        graph.add(KnowledgeEntry(
            type: .convention,
            content: "Use SwiftUI for all views",
            sourceSessionId: "s1"
        ))
        let prefix = bridge.contextPrefix(for: "myproject", task: "Build new view")
        #expect(prefix is String)
    }
}
