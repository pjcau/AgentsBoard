// MARK: - Project Manager Tests

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - ProjectInfo Tests

@Suite("ProjectInfo")
struct ProjectInfoTests {
    @Test func creation() {
        let project = ProjectInfo(
            id: "p1", name: "MyApp", path: "/Users/test/MyApp",
            configPath: "/Users/test/MyApp/.agentsboard.yml",
            isActive: true, createdAt: Date()
        )
        #expect(project.id == "p1")
        #expect(project.name == "MyApp")
        #expect(project.isActive)
    }

    @Test func codable() throws {
        let project = ProjectInfo(
            id: "p1", name: "Test", path: "/test",
            configPath: nil, isActive: false, createdAt: Date()
        )
        let data = try JSONEncoder().encode(project)
        let decoded = try JSONDecoder().decode(ProjectInfo.self, from: data)
        #expect(decoded.id == "p1")
        #expect(decoded.name == "Test")
        #expect(!decoded.isActive)
    }
}

// MARK: - ProjectManager Tests

@Suite("ProjectManager")
struct ProjectManagerTests {
    private func makeManager() -> ProjectManager {
        ProjectManager(persistence: MockPersistence(), yamlParser: MockYAMLParser())
    }

    @Test func initiallyEmpty() {
        let manager = makeManager()
        #expect(manager.projects.isEmpty)
    }

    @Test func addProject() throws {
        let manager = makeManager()
        let project = ProjectInfo(
            id: "p1", name: "Test", path: "/test",
            configPath: nil, isActive: true, createdAt: Date()
        )
        try manager.add(project)
        #expect(manager.projects.count == 1)
        #expect(manager.projects.first?.name == "Test")
    }

    @Test func removeProject() throws {
        let manager = makeManager()
        try manager.add(ProjectInfo(id: "p1", name: "Test", path: "/test", configPath: nil, isActive: true, createdAt: Date()))
        try manager.remove(projectId: "p1")
        #expect(manager.projects.isEmpty)
    }

    @Test func findById() throws {
        let manager = makeManager()
        try manager.add(ProjectInfo(id: "p1", name: "A", path: "/a", configPath: nil, isActive: true, createdAt: Date()))
        try manager.add(ProjectInfo(id: "p2", name: "B", path: "/b", configPath: nil, isActive: true, createdAt: Date()))

        #expect(manager.project(byId: "p2")?.name == "B")
    }

    @Test func findByPath() throws {
        let manager = makeManager()
        try manager.add(ProjectInfo(id: "p1", name: "A", path: "/path/to/a", configPath: nil, isActive: true, createdAt: Date()))

        #expect(manager.project(byPath: "/path/to/a")?.name == "A")
    }

    @Test func projectNotFound() {
        let manager = makeManager()
        #expect(manager.project(byId: "nonexistent") == nil)
        #expect(manager.project(byPath: "/nope") == nil)
    }

    @Test func sessionGrouping() throws {
        let manager = makeManager()
        try manager.add(ProjectInfo(id: "p1", name: "A", path: "/a", configPath: nil, isActive: true, createdAt: Date()))

        manager.assignSession("s1", toProject: "p1")
        manager.assignSession("s2", toProject: "p1")

        let sessions = manager.sessions(forProject: "p1")
        #expect(sessions.count == 2)
        #expect(sessions.contains("s1"))
        #expect(sessions.contains("s2"))
    }

    @Test func unassignSession() throws {
        let manager = makeManager()
        try manager.add(ProjectInfo(id: "p1", name: "A", path: "/a", configPath: nil, isActive: true, createdAt: Date()))

        manager.assignSession("s1", toProject: "p1")
        manager.unassignSession("s1")

        #expect(manager.sessions(forProject: "p1").isEmpty)
    }
}
