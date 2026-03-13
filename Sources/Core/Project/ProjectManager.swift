// MARK: - Project Manager (Step 4.2)

import Foundation
import Observation

@Observable
public final class ProjectManager: ProjectManaging, SessionGrouping {

    // MARK: - Properties

    public private(set) var projects: [ProjectInfo] = []
    public var onProjectsChange: (() -> Void)?

    private let persistence: any PersistenceProviding
    private let yamlParser: any YAMLParsing
    private var sessionAssignments: [String: String] = [:] // sessionId → projectId

    // MARK: - Init

    public init(persistence: any PersistenceProviding, yamlParser: any YAMLParsing) {
        self.persistence = persistence
        self.yamlParser = yamlParser
        loadProjects()
    }

    // MARK: - ProjectManaging

    public func discover(in directory: String) throws -> [ProjectInfo] {
        let fm = FileManager.default
        let configPath = (directory as NSString).appendingPathComponent("agentsboard.yml")

        guard fm.fileExists(atPath: configPath) else { return [] }

        let yaml = try String(contentsOfFile: configPath, encoding: .utf8)
        let config = try yamlParser.decode(ProjectConfig.self, from: yaml)

        let project = ProjectInfo(
            id: UUID().uuidString,
            name: config.name,
            path: directory,
            configPath: configPath,
            isActive: true,
            createdAt: Date()
        )

        return [project]
    }

    public func add(_ project: ProjectInfo) throws {
        guard !projects.contains(where: { $0.path == project.path }) else { return }
        projects.append(project)
        try persistence.save(project, in: "projects")
        onProjectsChange?()
    }

    public func remove(projectId: String) throws {
        projects.removeAll { $0.id == projectId }
        try persistence.delete(from: "projects", id: projectId)
        onProjectsChange?()
    }

    public func project(byId id: String) -> ProjectInfo? {
        projects.first { $0.id == id }
    }

    public func project(byPath path: String) -> ProjectInfo? {
        projects.first { $0.path == path }
    }

    // MARK: - SessionGrouping

    public func sessions(forProject projectId: String) -> [String] {
        sessionAssignments.filter { $0.value == projectId }.map(\.key)
    }

    public func assignSession(_ sessionId: String, toProject projectId: String) {
        sessionAssignments[sessionId] = projectId
    }

    public func unassignSession(_ sessionId: String) {
        sessionAssignments.removeValue(forKey: sessionId)
    }

    // MARK: - Private

    private func loadProjects() {
        projects = (try? persistence.fetchAll(from: "projects")) ?? []
    }
}
