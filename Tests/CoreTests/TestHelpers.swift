// MARK: - Shared Test Helpers & Mocks

import Foundation
@testable import AgentsBoardCore

// MARK: - Mock Persistence

final class MockPersistence: PersistenceProviding {
    public func save<T: Codable & Identifiable>(_ record: T, in table: String) throws {}
    public func fetch<T: Codable & Identifiable>(from table: String, id: String) throws -> T? { nil }
    public func fetchAll<T: Codable & Identifiable>(from table: String) throws -> [T] { [] }
    public func delete(from table: String, id: String) throws {}
    public func deleteAll(from table: String) throws {}
    public func query<T: Codable>(sql: String, arguments: [Any]) throws -> [T] { [] }
}

// MARK: - Mock YAML Parser

final class MockYAMLParser: YAMLParsing {
    public func decode<T: Decodable>(_ type: T.Type, from yaml: String) throws -> T {
        fatalError("Not implemented in tests")
    }
    public func encode<T: Encodable>(_ value: T) throws -> String {
        fatalError("Not implemented in tests")
    }
}

// MARK: - Factory Helpers

func makeModel(name: String = "Opus", provider: AgentProvider = .claude) -> ModelIdentifier {
    ModelIdentifier(name: name, provider: provider, version: nil)
}

func makeCostEntry(
    provider: AgentProvider = .claude,
    cost: Decimal = 0.05,
    sessionId: String = "s1"
) -> CostEntry {
    CostEntry(
        provider: provider,
        model: makeModel(),
        inputTokens: 1000,
        outputTokens: 500,
        cost: cost,
        sessionId: sessionId
    )
}
