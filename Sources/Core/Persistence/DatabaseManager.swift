// MARK: - Database Manager (Step 1.4)
// DIP wrapper around GRDB. This is the ONLY file that imports GRDB.

import Foundation
import GRDB

/// Concrete persistence implementation backed by SQLite via GRDB.
final class DatabaseManager: PersistenceProviding {

    private let dbQueue: DatabaseQueue

    // MARK: - Init

    init(path: String? = nil) throws {
        let dbPath = path ?? Self.defaultDatabasePath()
        let dir = (dbPath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        dbQueue = try DatabaseQueue(path: dbPath)
        try runMigrations()
    }

    static func defaultDatabasePath() -> String {
        "\(NSHomeDirectory())/Library/Application Support/AgentsBoard/agentsboard.db"
    }

    // MARK: - Migrations

    private func runMigrations() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial") { db in
            // Sessions table
            try db.create(table: "sessions", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("name", .text)
                t.column("provider", .text).notNull()
                t.column("model", .text)
                t.column("projectId", .text)
                t.column("launchCommand", .text).notNull()
                t.column("startTime", .datetime).notNull()
                t.column("endTime", .datetime)
                t.column("data", .blob)
            }

            // Projects table
            try db.create(table: "projects", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("path", .text).notNull().unique()
                t.column("configPath", .text)
                t.column("isActive", .boolean).notNull().defaults(to: true)
                t.column("createdAt", .datetime).notNull()
                t.column("data", .blob)
            }

            // Cost entries table
            try db.create(table: "cost_entries", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("provider", .text).notNull()
                t.column("model", .text).notNull()
                t.column("inputTokens", .integer).notNull()
                t.column("outputTokens", .integer).notNull()
                t.column("cost", .double).notNull()
                t.column("timestamp", .datetime).notNull()
                t.column("sessionId", .text).notNull()
                t.column("taskId", .text)
                t.column("data", .blob)
            }

            // Activity events table
            try db.create(table: "activity_events", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("sessionId", .text).notNull()
                t.column("eventType", .text).notNull()
                t.column("timestamp", .datetime).notNull()
                t.column("details", .text)
                t.column("cost", .double)
                t.column("data", .blob)
            }

            // Preferences table
            try db.create(table: "preferences", ifNotExists: true) { t in
                t.primaryKey("key", .text)
                t.column("value", .text).notNull()
            }

            // Indexes
            try db.create(indexOn: "cost_entries", columns: ["sessionId"])
            try db.create(indexOn: "cost_entries", columns: ["timestamp"])
            try db.create(indexOn: "activity_events", columns: ["sessionId"])
            try db.create(indexOn: "activity_events", columns: ["timestamp"])
        }

        try migrator.migrate(dbQueue)
    }

    // MARK: - PersistenceProviding

    func save<T: Codable & Identifiable>(_ record: T, in table: String) throws {
        let data = try JSONEncoder().encode(record)
        let idString = String(describing: record.id)
        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT OR REPLACE INTO \(table) (id, data) VALUES (?, ?)",
                arguments: [idString, data]
            )
        }
    }

    func fetch<T: Codable & Identifiable>(from table: String, id: String) throws -> T? {
        try dbQueue.read { db in
            if let row = try Row.fetchOne(db, sql: "SELECT data FROM \(table) WHERE id = ?", arguments: [id]),
               let data = row["data"] as? Data {
                return try JSONDecoder().decode(T.self, from: data)
            }
            return nil
        }
    }

    func fetchAll<T: Codable & Identifiable>(from table: String) throws -> [T] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT data FROM \(table)")
            return try rows.compactMap { row in
                guard let data = row["data"] as? Data else { return nil }
                return try JSONDecoder().decode(T.self, from: data)
            }
        }
    }

    func delete(from table: String, id: String) throws {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM \(table) WHERE id = ?", arguments: [id])
        }
    }

    func deleteAll(from table: String) throws {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM \(table)")
        }
    }

    func query<T: Codable>(sql: String, arguments: [Any]) throws -> [T] {
        try dbQueue.read { db in
            let rows = try Row.fetchAll(db, sql: sql)
            return try rows.compactMap { row in
                guard let data = row["data"] as? Data else { return nil }
                return try JSONDecoder().decode(T.self, from: data)
            }
        }
    }
}
