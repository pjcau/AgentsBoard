// MARK: - VT Parser (Step 2.3)
// Wraps SwiftTerm behind protocol for DIP. Converts byte stream → terminal grid.

import Foundation

#if canImport(SwiftTerm)
import SwiftTerm

final class VTParser {

    // MARK: - Properties

    private let terminal: Terminal
    private(set) var columns: Int
    private(set) var rows: Int

    // MARK: - Init

    private final class NoOpDelegate: TerminalDelegate {
        func send(source: Terminal, data: ArraySlice<UInt8>) {}
    }

    private let delegate = NoOpDelegate()

    init(columns: Int = 80, rows: Int = 24) {
        self.columns = columns
        self.rows = rows
        self.terminal = Terminal(delegate: delegate, options: TerminalOptions(cols: columns, rows: rows))
    }

    // MARK: - Feed Data

    func feed(_ data: Data) {
        let bytes = [UInt8](data)
        terminal.feed(byteArray: bytes)
    }

    // MARK: - Resize

    func resize(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        terminal.resize(cols: columns, rows: rows)
    }

    // MARK: - Snapshot

    /// Uses SwiftTerm's public getCharData API to build a grid snapshot.
    func snapshot() -> TerminalGridSnapshot {
        var cells: [TerminalCell] = []
        cells.reserveCapacity(columns * rows)

        for row in 0..<rows {
            for col in 0..<columns {
                let ch = terminal.getCharData(col: col, row: row)
                let character = ch?.getCharacter() ?? " "

                cells.append(TerminalCell(
                    character: Character(String(character)),
                    foreground: .default,
                    background: .default,
                    attributes: CellAttributes()
                ))
            }
        }

        return TerminalGridSnapshot(columns: columns, rows: rows, cells: cells)
    }

    // MARK: - Cursor

    func cursorPosition() -> CursorPosition {
        let loc = terminal.getCursorLocation()
        return CursorPosition(
            column: loc.x,
            row: loc.y,
            isVisible: true
        )
    }
}

#else

// MARK: - VTParser Stub (non-macOS platforms without SwiftTerm)

final class VTParserStub {

    private(set) var columns: Int
    private(set) var rows: Int

    init(columns: Int = 80, rows: Int = 24) {
        self.columns = columns
        self.rows = rows
    }

    func feed(_ data: Data) {}

    func resize(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }

    func snapshot() -> TerminalGridSnapshot {
        let cells = [TerminalCell](
            repeating: TerminalCell(
                character: " ",
                foreground: .default,
                background: .default,
                attributes: CellAttributes()
            ),
            count: columns * rows
        )
        return TerminalGridSnapshot(columns: columns, rows: rows, cells: cells)
    }

    func cursorPosition() -> CursorPosition {
        CursorPosition(column: 0, row: 0, isVisible: true)
    }
}

#endif
