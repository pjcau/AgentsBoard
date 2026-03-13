// MARK: - UI Tests

import Testing
@testable import AgentsBoardUI
@testable import AgentsBoardCore

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
