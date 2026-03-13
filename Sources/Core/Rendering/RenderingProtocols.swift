// MARK: - Rendering Protocols

import Foundation

/// Renders terminal cell grids to a display surface (Metal).
public protocol TerminalRenderable: AnyObject {
    func render(viewports: [TerminalViewportData])
    func updateGlyphAtlas(fontFamily: String, fontSize: CGFloat)
    func invalidate()
}

/// Data needed to render a single terminal viewport.
public struct TerminalViewportData: Sendable {
    public let sessionId: String
    public let rect: ViewportRect
    public let grid: TerminalGridSnapshot
    public let cursorPosition: CursorPosition?
    public let isFocused: Bool

    public init(sessionId: String, rect: ViewportRect, grid: TerminalGridSnapshot, cursorPosition: CursorPosition?, isFocused: Bool) {
        self.sessionId = sessionId
        self.rect = rect
        self.grid = grid
        self.cursorPosition = cursorPosition
        self.isFocused = isFocused
    }
}

/// A rectangle within the render surface.
public struct ViewportRect: Equatable, Sendable {
    public let x: CGFloat
    public let y: CGFloat
    public let width: CGFloat
    public let height: CGFloat

    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// Snapshot of a terminal grid for rendering (immutable, sendable).
public struct TerminalGridSnapshot: Sendable {
    public let columns: Int
    public let rows: Int
    public let cells: [TerminalCell]

    public init(columns: Int, rows: Int, cells: [TerminalCell]) {
        self.columns = columns
        self.rows = rows
        self.cells = cells
    }
}

/// A single cell in the terminal grid.
public struct TerminalCell: Sendable {
    public let character: Character
    public let foreground: TerminalColor
    public let background: TerminalColor
    public let attributes: CellAttributes

    public init(character: Character, foreground: TerminalColor, background: TerminalColor, attributes: CellAttributes) {
        self.character = character
        self.foreground = foreground
        self.background = background
        self.attributes = attributes
    }
}

/// Terminal color (ANSI 256 + TrueColor).
public enum TerminalColor: Sendable, Equatable {
    case ansi(UInt8)
    case rgb(r: UInt8, g: UInt8, b: UInt8)
    case `default`
}

/// Text attributes for a terminal cell.
public struct CellAttributes: OptionSet, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let bold = CellAttributes(rawValue: 1 << 0)
    public static let italic = CellAttributes(rawValue: 1 << 1)
    public static let underline = CellAttributes(rawValue: 1 << 2)
    public static let strikethrough = CellAttributes(rawValue: 1 << 3)
    public static let dim = CellAttributes(rawValue: 1 << 4)
    public static let inverse = CellAttributes(rawValue: 1 << 5)
}

/// Cursor position in the terminal grid.
public struct CursorPosition: Equatable, Sendable {
    public let column: Int
    public let row: Int
    public let isVisible: Bool

    public init(column: Int, row: Int, isVisible: Bool) {
        self.column = column
        self.row = row
        self.isVisible = isVisible
    }
}
