// MARK: - Terminal Grid (Step 2.3)
// Manages the terminal cell grid with circular scroll buffer.

import Foundation

final class TerminalGrid {

    // MARK: - Properties

    private(set) var columns: Int
    private(set) var rows: Int
    private(set) var scrollbackLimit: Int

    private var buffer: [[TerminalCell]]
    private var scrollbackBuffer: [[TerminalCell]]
    private var scrollOffset: Int = 0

    // MARK: - Init

    init(columns: Int = 80, rows: Int = 24, scrollbackLimit: Int = 10000) {
        self.columns = columns
        self.rows = rows
        self.scrollbackLimit = scrollbackLimit

        let emptyCell = TerminalCell(character: " ", foreground: .default, background: .default, attributes: [])
        let emptyRow = Array(repeating: emptyCell, count: columns)
        self.buffer = Array(repeating: emptyRow, count: rows)
        self.scrollbackBuffer = []
    }

    // MARK: - Update from VT Parser

    func update(from snapshot: TerminalGridSnapshot) {
        guard snapshot.columns == columns, snapshot.rows == rows else { return }

        for row in 0..<rows {
            for col in 0..<columns {
                let index = row * columns + col
                guard index < snapshot.cells.count else { break }
                buffer[row][col] = snapshot.cells[index]
            }
        }
    }

    // MARK: - Resize

    func resize(newColumns: Int, newRows: Int) {
        let emptyCell = TerminalCell(character: " ", foreground: .default, background: .default, attributes: [])

        // Resize each existing row
        var newBuffer: [[TerminalCell]] = []
        for row in 0..<min(newRows, buffer.count) {
            var newRow = buffer[row]
            if newColumns > columns {
                newRow.append(contentsOf: Array(repeating: emptyCell, count: newColumns - columns))
            } else if newColumns < columns {
                newRow = Array(newRow.prefix(newColumns))
            }
            newBuffer.append(newRow)
        }

        // Add new empty rows if needed
        while newBuffer.count < newRows {
            newBuffer.append(Array(repeating: emptyCell, count: newColumns))
        }

        self.buffer = newBuffer
        self.columns = newColumns
        self.rows = newRows
    }

    // MARK: - Scroll

    func scrollUp(lines: Int = 1) {
        scrollOffset = min(scrollOffset + lines, scrollbackBuffer.count)
    }

    func scrollDown(lines: Int = 1) {
        scrollOffset = max(scrollOffset - lines, 0)
    }

    func scrollToBottom() {
        scrollOffset = 0
    }

    // MARK: - Snapshot for Rendering

    func renderSnapshot() -> TerminalGridSnapshot {
        let flatCells = buffer.flatMap { $0 }
        return TerminalGridSnapshot(columns: columns, rows: rows, cells: flatCells)
    }

    // MARK: - Clear

    func clear() {
        let emptyCell = TerminalCell(character: " ", foreground: .default, background: .default, attributes: [])
        let emptyRow = Array(repeating: emptyCell, count: columns)
        buffer = Array(repeating: emptyRow, count: rows)
        scrollbackBuffer.removeAll()
        scrollOffset = 0
    }
}
