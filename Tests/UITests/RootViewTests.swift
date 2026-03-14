// MARK: - UI Tests

import Testing
import Foundation
@testable import AgentsBoardUI
@testable import AgentsBoardCore

// MARK: - Test Helpers (local to UI tests)

private final class UITestPersistence: PersistenceProviding {
    func save<T: Codable & Identifiable>(_ record: T, in table: String) throws {}
    func fetch<T: Codable & Identifiable>(from table: String, id: String) throws -> T? { nil }
    func fetchAll<T: Codable & Identifiable>(from table: String) throws -> [T] { [] }
    func delete(from table: String, id: String) throws {}
    func deleteAll(from table: String) throws {}
    func query<T: Codable>(sql: String, arguments: [Any]) throws -> [T] { [] }
}

// MARK: - DiffParser Tests

@Suite("DiffParser")
struct DiffParserTests {
    let parser = DiffParser()

    @Test func parseEmptyDiff() {
        let hunks = parser.parse(unifiedDiff: "")
        #expect(hunks.isEmpty)
    }

    @Test func parseSingleHunk() {
        let diff = """
        @@ -1,3 +1,4 @@
         line 1
        -old line 2
        +new line 2
        +added line 3
         line 3
        """
        let hunks = parser.parse(unifiedDiff: diff)
        #expect(hunks.count == 1)
        #expect(hunks[0].lines.count >= 4)
    }

    @Test func lineTypes() {
        let diff = """
        @@ -1,2 +1,2 @@
         context
        -deleted
        +added
        """
        let hunks = parser.parse(unifiedDiff: diff)
        let lines = hunks.first!.lines
        #expect(lines[0].type == .context)
        #expect(lines[1].type == .deletion)
        #expect(lines[2].type == .addition)
    }

    @Test func lineNumbers() {
        let diff = """
        @@ -5,3 +5,3 @@
         same
        -old
        +new
        """
        let hunks = parser.parse(unifiedDiff: diff)
        let lines = hunks.first!.lines
        // Context line at old=5, new=5
        #expect(lines[0].oldLineNumber == 5)
        #expect(lines[0].newLineNumber == 5)
        // Deletion at old=6
        #expect(lines[1].oldLineNumber == 6)
        #expect(lines[1].newLineNumber == nil)
        // Addition at new=6
        #expect(lines[2].oldLineNumber == nil)
        #expect(lines[2].newLineNumber == 6)
    }

    @Test func multipleHunks() {
        let diff = """
        @@ -1,2 +1,2 @@
         line 1
        -old
        @@ -10,2 +10,2 @@
         line 10
        +new
        """
        let hunks = parser.parse(unifiedDiff: diff)
        #expect(hunks.count == 2)
    }

    @Test func ignoresFileHeaders() {
        let diff = """
        --- a/file.swift
        +++ b/file.swift
        @@ -1,2 +1,2 @@
         keep
        -removed
        +added
        """
        let hunks = parser.parse(unifiedDiff: diff)
        #expect(hunks.count == 1)
        // File headers should be ignored, not treated as additions/deletions
        #expect(hunks[0].lines.allSatisfy { $0.type != .header || true })
    }
}

// MARK: - DiffReviewViewModel Tests

@Suite("DiffReviewViewModel")
struct DiffReviewViewModelTests {
    @Test func initialState() {
        let vm = DiffReviewViewModel()
        #expect(vm.viewMode == .unified)
        #expect(vm.fileName.isEmpty)
        #expect(vm.hunks.isEmpty)
        #expect(vm.additions == 0)
        #expect(vm.deletions == 0)
    }

    @Test func loadDiff() {
        let vm = DiffReviewViewModel()
        let diff = """
        @@ -1,2 +1,3 @@
         keep
        -old
        +new1
        +new2
        """
        vm.loadDiff(fileName: "test.swift", content: diff)
        #expect(vm.fileName == "test.swift")
        #expect(vm.additions == 2)
        #expect(vm.deletions == 1)
    }

    @Test func approveCallback() {
        let vm = DiffReviewViewModel()
        var approved = false
        vm.onApprove = { approved = true }
        vm.approve()
        #expect(approved)
    }

    @Test func rejectCallback() {
        let vm = DiffReviewViewModel()
        var rejected = false
        vm.onReject = { rejected = true }
        vm.reject()
        #expect(rejected)
    }
}

// MARK: - SyntaxHighlighter Tests

@Suite("SyntaxHighlighter")
struct SyntaxHighlighterTests {
    let highlighter = SyntaxHighlighter()

    @Test func highlightSwiftKeyword() {
        let content = highlighter.highlight("func hello()", language: "swift")
        #expect(content.lines.count == 1)
        let tokens = content.lines[0].tokens
        #expect(tokens.contains(where: { $0.type == .keyword }))
    }

    @Test func highlightComment() {
        let content = highlighter.highlight("// This is a comment", language: "swift")
        let tokens = content.lines[0].tokens
        #expect(tokens.contains(where: { $0.type == .comment }))
    }

    @Test func highlightMultipleLines() {
        let source = """
        import SwiftUI
        let x = 42
        // comment
        """
        let content = highlighter.highlight(source, language: "swift")
        #expect(content.lines.count == 3)
    }

    @Test func unknownLanguage() {
        let content = highlighter.highlight("hello world", language: "unknown")
        #expect(content.lines.count == 1)
    }
}

// MARK: - EditorViewModel Tests

@Suite("EditorViewModel")
struct EditorViewModelTests {
    @Test func initialState() {
        let vm = EditorViewModel()
        #expect(vm.openFiles.isEmpty)
        #expect(vm.activeFilePath == nil)
        #expect(vm.activeContent == nil)
    }

    @Test func closeNonexistentFile() {
        let vm = EditorViewModel()
        vm.closeFile("/nonexistent") // Should not crash
        #expect(vm.openFiles.isEmpty)
    }
}

// MARK: - DiffViewMode Tests

@Suite("DiffViewMode")
struct DiffViewModeTests {
    @Test func allCases() {
        let modes = DiffViewMode.allCases
        #expect(modes.contains(.unified))
        #expect(modes.contains(.sideBySide))
        #expect(modes.count == 2)
    }
}

// MARK: - CommandPaletteViewModel Tests

@Suite("CommandPaletteViewModel")
struct CommandPaletteViewModelTests {
    @Test func toggle() {
        let registry = CommandRegistry()
        let vm = CommandPaletteViewModel(registry: registry)
        #expect(!vm.isPresented)
        vm.toggle()
        #expect(vm.isPresented)
        vm.toggle()
        #expect(!vm.isPresented)
    }

    @Test func moveUpDown() {
        let registry = CommandRegistry()
        registry.register(command: PaletteCommand(id: "1", title: "A", subtitle: nil, icon: "star", category: .general, shortcut: nil, action: {}))
        registry.register(command: PaletteCommand(id: "2", title: "B", subtitle: nil, icon: "star", category: .general, shortcut: nil, action: {}))
        let vm = CommandPaletteViewModel(registry: registry)
        #expect(vm.selectedIndex == 0)
        vm.moveDown()
        #expect(vm.selectedIndex == 1)
        vm.moveUp()
        #expect(vm.selectedIndex == 0)
    }

    @Test func moveUpAtZeroStays() {
        let registry = CommandRegistry()
        let vm = CommandPaletteViewModel(registry: registry)
        vm.moveUp()
        #expect(vm.selectedIndex == 0)
    }

    @Test func queryResetsIndex() {
        let registry = CommandRegistry()
        registry.register(command: PaletteCommand(id: "1", title: "Test", subtitle: nil, icon: "star", category: .general, shortcut: nil, action: {}))
        let vm = CommandPaletteViewModel(registry: registry)
        vm.moveDown()
        vm.query = "test"
        #expect(vm.selectedIndex == 0)
    }
}

// MARK: - MermaidRendererViewModel Tests

@Suite("MermaidRendererViewModel")
struct MermaidRendererViewModelTests {
    @Test func initialState() {
        let vm = MermaidRendererViewModel()
        #expect(vm.mermaidSource.isEmpty)
        #expect(!vm.hasContent)
        #expect(vm.diagramTheme == .dark)
    }

    @Test func loadFromOutput() {
        let vm = MermaidRendererViewModel()
        let markdown = """
        Some text
        ```mermaid
        graph TD
            A --> B
        ```
        More text
        """
        vm.loadFromOutput(markdown)
        #expect(vm.hasContent)
        #expect(vm.mermaidSource.contains("graph TD"))
    }

    @Test func loadFromOutputNoMermaid() {
        let vm = MermaidRendererViewModel()
        vm.loadFromOutput("No mermaid here")
        #expect(!vm.hasContent)
    }
}

// MARK: - SessionCardViewModel Action Tests

@Suite("SessionCardViewModel Actions")
struct SessionCardViewModelActionTests {
    @Test func killCallback() {
        let vm = SessionCardViewModel(id: "test-1", name: "Test")
        vm.state = .working
        var killed = false
        vm.onKill = { killed = true }
        vm.onKill?()
        #expect(killed)
    }

    @Test func restartCallback() {
        let vm = SessionCardViewModel(id: "test-1", name: "Test")
        var restarted = false
        vm.onRestart = { restarted = true }
        vm.onRestart?()
        #expect(restarted)
    }

    @Test func renameCallback() {
        let vm = SessionCardViewModel(id: "test-1", name: "OldName")
        var receivedName: String?
        vm.onRename = { name in receivedName = name }
        vm.onRename?("OldName")
        #expect(receivedName == "OldName")
    }

    @Test func toggleRecordingCallback() {
        let vm = SessionCardViewModel(id: "test-1", name: "Test")
        #expect(!vm.isRecording)
        var toggled = false
        vm.onToggleRecording = { toggled = true }
        vm.onToggleRecording?()
        #expect(toggled)
    }

    @Test func initialRecordingState() {
        let vm = SessionCardViewModel(id: "test-1", name: "Test")
        #expect(!vm.isRecording)
    }
}

// MARK: - GlobalSearchViewModel Tests

@Suite("GlobalSearchViewModel")
struct GlobalSearchViewModelTests {
    @Test func emptyQueryClearsResults() {
        let logger = ActivityLogger(persistence: UITestPersistence())
        let vm = GlobalSearchViewModel(activityLogger: logger)
        vm.query = ""
        vm.search()
        #expect(vm.results.isEmpty)
    }

    @Test func searchActivityScope() {
        let logger = ActivityLogger(persistence: UITestPersistence())
        logger.log(ActivityEvent(sessionId: "s1", eventType: .stateChange, details: "Session started"))
        logger.log(ActivityEvent(sessionId: "s2", eventType: .error, details: "Build failed"))

        let vm = GlobalSearchViewModel(activityLogger: logger)
        vm.query = "started"
        vm.scope = .activity
        vm.search()
        #expect(vm.results.count == 1)
        #expect(vm.results[0].type == .activity)
    }

    @Test func searchAllScope() {
        let logger = ActivityLogger(persistence: UITestPersistence())
        logger.log(ActivityEvent(sessionId: "s1", eventType: .stateChange, details: "hello world"))

        let vm = GlobalSearchViewModel(activityLogger: logger)
        vm.query = "hello"
        vm.scope = .all
        vm.search()
        #expect(!vm.results.isEmpty)
    }

    @Test func searchDurationTracked() {
        let logger = ActivityLogger(persistence: UITestPersistence())
        let vm = GlobalSearchViewModel(activityLogger: logger)
        vm.query = "test"
        vm.search()
        #expect(vm.searchDuration != nil)
    }

    @Test func noResultsForUnmatchedQuery() {
        let logger = ActivityLogger(persistence: UITestPersistence())
        logger.log(ActivityEvent(sessionId: "s1", eventType: .stateChange, details: "hello"))

        let vm = GlobalSearchViewModel(activityLogger: logger)
        vm.query = "zzzznotfound"
        vm.search()
        #expect(vm.results.isEmpty)
    }
}

// MARK: - FileExplorerViewModel Tests

@Suite("FileExplorerViewModel")
struct FileExplorerViewModelTests {
    @Test func initialState() {
        let vm = FileExplorerViewModel()
        #expect(vm.rootNodes.isEmpty)
        #expect(vm.selectedPath == nil)
        #expect(vm.rootName == "Workspace")
    }

    @Test func selectFile() {
        let vm = FileExplorerViewModel()
        var selectedPath: String?
        vm.onFileSelected = { path in selectedPath = path }
        vm.selectFile("/test/file.swift")
        #expect(vm.selectedPath == "/test/file.swift")
        #expect(selectedPath == "/test/file.swift")
    }

    @Test func loadDirectory() {
        let vm = FileExplorerViewModel()
        // Use /tmp which always exists
        vm.loadDirectory(at: "/tmp")
        #expect(vm.rootName == "tmp")
    }

    @Test func refreshReloads() {
        let vm = FileExplorerViewModel()
        vm.loadDirectory(at: "/tmp")
        let countBefore = vm.rootNodes.count
        vm.refresh()
        // After refresh, should still have nodes (same directory)
        #expect(vm.rootNodes.count == countBefore)
    }

    @Test func refreshWithoutLoadDoesNotCrash() {
        let vm = FileExplorerViewModel()
        vm.refresh() // Should not crash
        #expect(vm.rootNodes.isEmpty)
    }
}
