// MARK: - Rendering Model Tests

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - ViewportRect Tests

@Suite("ViewportRect")
struct ViewportRectTests {
    @Test func creation() {
        let rect = ViewportRect(x: 10, y: 20, width: 800, height: 600)
        #expect(rect.x == 10)
        #expect(rect.y == 20)
        #expect(rect.width == 800)
        #expect(rect.height == 600)
    }
}

// MARK: - TerminalViewportData Tests

@Suite("TerminalViewportData")
struct TerminalViewportDataTests {
    @Test func creation() {
        let grid = TerminalGridSnapshot(columns: 80, rows: 24, cells: [])
        let cursor = CursorPosition(column: 0, row: 0, isVisible: true)
        let rect = ViewportRect(x: 0, y: 0, width: 800, height: 600)
        let viewport = TerminalViewportData(
            sessionId: "s1", rect: rect,
            grid: grid, cursorPosition: cursor, isFocused: true
        )
        #expect(viewport.sessionId == "s1")
        #expect(viewport.isFocused)
    }
}

// MARK: - TerminalGridSnapshot Populated Tests

@Suite("TerminalGridSnapshotPopulated")
struct TerminalGridSnapshotPopulatedTests {
    @Test func withCells() {
        let cells = [
            TerminalCell(character: "H", foreground: .default, background: .default, attributes: []),
            TerminalCell(character: "i", foreground: .default, background: .default, attributes: []),
        ]
        let snapshot = TerminalGridSnapshot(columns: 2, rows: 1, cells: cells)
        #expect(snapshot.cells.count == 2)
        #expect(snapshot.cells[0].character == "H")
        #expect(snapshot.cells[1].character == "i")
    }
}
