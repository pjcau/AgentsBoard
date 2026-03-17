// MARK: - Rendering Protocols

import Foundation

/// Renders terminal cell grids to a display surface (Metal).
public protocol TerminalRenderable: AnyObject {
    func render(viewports: [TerminalViewportData])
    func updateGlyphAtlas(fontFamily: String, fontSize: Double)
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
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
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

// MARK: - TerminalCell
//
// Memory layout (target ≤16 bytes):
//   codepoint:  UInt32  — 4 bytes (Unicode scalar value)
//   foreground: UInt32  — 4 bytes (packed color, see TerminalColor.packed)
//   background: UInt32  — 4 bytes (packed color)
//   attributes: UInt8   — 1 byte  (CellAttributes.rawValue)
//   _pad:       UInt8×3 — 3 bytes (Swift struct padding)
//                       = 16 bytes total stride

/// A single cell in the terminal grid.
///
/// Stored compactly as two UInt32 packed colors and a UInt32 codepoint.
/// Public API preserves `character: Character` as a computed property for
/// call-site convenience — no binary break for existing callers.
public struct TerminalCell: Sendable {

    // MARK: - Stored (compact) fields

    /// Unicode codepoint (scalar value) of the displayed character.
    public let codepoint: UInt32

    /// Packed foreground color. Use `TerminalColor(packed:)` to unpack.
    public let foreground: UInt32

    /// Packed background color. Use `TerminalColor(packed:)` to unpack.
    public let background: UInt32

    /// Raw attribute bitmask — use `CellAttributes(rawValue:)` to interpret.
    public let attributesRaw: UInt8

    // Three bytes of natural padding follow attributesRaw to reach 16-byte stride.
    private let _pad0: UInt8 = 0
    private let _pad1: UInt8 = 0
    private let _pad2: UInt8 = 0

    // MARK: - Convenience computed properties

    /// The Unicode character represented by this cell.
    @inline(__always)
    public var character: Character {
        guard let scalar = Unicode.Scalar(codepoint) else { return " " }
        return Character(scalar)
    }

    /// Decoded foreground `TerminalColor`.
    @inline(__always)
    public var foregroundColor: TerminalColor { TerminalColor(packed: foreground) }

    /// Decoded background `TerminalColor`.
    @inline(__always)
    public var backgroundColor: TerminalColor { TerminalColor(packed: background) }

    /// Decoded `CellAttributes`.
    @inline(__always)
    public var attributes: CellAttributes { CellAttributes(rawValue: attributesRaw) }

    // MARK: - Initialisers

    /// Primary compact initialiser — callers that already hold packed values
    /// avoid the pack/unpack round-trip.
    public init(codepoint: UInt32, foreground: UInt32, background: UInt32, attributesRaw: UInt8) {
        self.codepoint = codepoint
        self.foreground = foreground
        self.background = background
        self.attributesRaw = attributesRaw
    }

    /// Convenience initialiser using `Character` and `TerminalColor` — keeps
    /// all existing call sites compiling without changes.
    public init(character: Character, foreground: TerminalColor, background: TerminalColor, attributes: CellAttributes) {
        self.codepoint = character.unicodeScalars.first?.value ?? 0x20
        self.foreground = foreground.packed
        self.background = background.packed
        self.attributesRaw = attributes.rawValue
    }
}

// MARK: - TerminalColor
//
// Packed UInt32 encoding:
//   .default      →  0xFF_00_00_00  (tag 0xFF, remaining bytes unused)
//   .ansi(code)   →  0xFE_00_00_code  (tag 0xFE, lower byte = ANSI code)
//   .rgb(r,g,b)   →  0x00_rr_gg_bb  (tag 0x00, lower 3 bytes = RGB)
//
// This keeps the enum as the public API while adding O(1) storage helpers.

/// Terminal color (ANSI 256 + TrueColor).
public enum TerminalColor: Sendable, Equatable {
    case ansi(UInt8)
    case rgb(r: UInt8, g: UInt8, b: UInt8)
    case `default`

    // MARK: - Packed storage

    private static let tagDefault: UInt32 = 0xFF00_0000
    private static let tagAnsi:    UInt32 = 0xFE00_0000
    private static let tagRGB:     UInt32 = 0x0000_0000

    /// Pack the color into a 4-byte value suitable for compact storage.
    @inline(__always)
    public var packed: UInt32 {
        switch self {
        case .default:
            return TerminalColor.tagDefault
        case .ansi(let code):
            return TerminalColor.tagAnsi | UInt32(code)
        case .rgb(let r, let g, let b):
            return TerminalColor.tagRGB | (UInt32(r) << 16) | (UInt32(g) << 8) | UInt32(b)
        }
    }

    /// Unpack a color from a value previously produced by `packed`.
    @inline(__always)
    public init(packed value: UInt32) {
        let tag = value & 0xFF00_0000
        switch tag {
        case TerminalColor.tagDefault:
            self = .default
        case TerminalColor.tagAnsi:
            self = .ansi(UInt8(value & 0xFF))
        default:
            // tagRGB (0x00) — also the fallback for any unknown tag
            let r = UInt8((value >> 16) & 0xFF)
            let g = UInt8((value >>  8) & 0xFF)
            let b = UInt8( value        & 0xFF)
            self = .rgb(r: r, g: g, b: b)
        }
    }
}

/// Text attributes for a terminal cell.
public struct CellAttributes: OptionSet, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let bold          = CellAttributes(rawValue: 1 << 0)
    public static let italic        = CellAttributes(rawValue: 1 << 1)
    public static let underline     = CellAttributes(rawValue: 1 << 2)
    public static let strikethrough = CellAttributes(rawValue: 1 << 3)
    public static let dim           = CellAttributes(rawValue: 1 << 4)
    public static let inverse       = CellAttributes(rawValue: 1 << 5)
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
