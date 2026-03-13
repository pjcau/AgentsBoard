// MARK: - Project Protocols

import Foundation

/// Manages projects: discovery, CRUD, persistence.
public protocol ProjectManaging: AnyObject {
    var projects: [ProjectInfo] { get }

    func discover(in directory: String) throws -> [ProjectInfo]
    func add(_ project: ProjectInfo) throws
    func remove(projectId: String) throws
    func project(byId id: String) -> ProjectInfo?
    func project(byPath path: String) -> ProjectInfo?

    var onProjectsChange: (() -> Void)? { get set }
}

/// Groups sessions by project.
public protocol SessionGrouping {
    func sessions(forProject projectId: String) -> [String]
    func assignSession(_ sessionId: String, toProject projectId: String)
    func unassignSession(_ sessionId: String)
}

/// Project data model.
public struct ProjectInfo: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let path: String
    public let configPath: String?
    public let isActive: Bool
    public let createdAt: Date

    public init(id: String, name: String, path: String, configPath: String?, isActive: Bool, createdAt: Date) {
        self.id = id
        self.name = name
        self.path = path
        self.configPath = configPath
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
