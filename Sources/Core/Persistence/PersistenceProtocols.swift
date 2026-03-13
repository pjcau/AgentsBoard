// MARK: - Persistence Protocols (DIP: abstracts SQLite/GRDB)

import Foundation

/// Provides persistence operations. No GRDB types leak through this protocol.
public protocol PersistenceProviding: AnyObject {
    func save<T: Codable & Identifiable>(_ record: T, in table: String) throws
    func fetch<T: Codable & Identifiable>(from table: String, id: String) throws -> T?
    func fetchAll<T: Codable & Identifiable>(from table: String) throws -> [T]
    func delete(from table: String, id: String) throws
    func deleteAll(from table: String) throws
    func query<T: Codable>(sql: String, arguments: [Any]) throws -> [T]
}
