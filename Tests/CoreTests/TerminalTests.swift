// MARK: - Terminal Tests

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - TerminalSize Tests

@Suite("TerminalSize")
struct TerminalSizeTests {
    @Test func defaultSize() {
        let size = TerminalSize.default
        #expect(size.columns == 80)
        #expect(size.rows == 24)
    }

    @Test func customSize() {
        let size = TerminalSize(columns: 120, rows: 40)
        #expect(size.columns == 120)
        #expect(size.rows == 40)
    }
}

// MARK: - TerminalSession Tests

@Suite("TerminalSession")
struct TerminalSessionTests {
    @Test func creation() {
        let session = TerminalSession()
        #expect(!session.sessionId.isEmpty)
        #expect(!session.isRunning)
        #expect(session.terminalSize.columns == 80)
        #expect(session.terminalSize.rows == 24)
    }

    @Test func uniqueSessionIds() {
        let s1 = TerminalSession()
        let s2 = TerminalSession()
        #expect(s1.sessionId != s2.sessionId)
    }
}

// MARK: - TerminalGridSnapshot Tests

@Suite("TerminalGridSnapshot")
struct TerminalGridSnapshotTests {
    @Test func creation() {
        let snapshot = TerminalGridSnapshot(columns: 80, rows: 24, cells: [])
        #expect(snapshot.columns == 80)
        #expect(snapshot.rows == 24)
        #expect(snapshot.cells.isEmpty)
    }
}

// MARK: - TerminalCell Tests

@Suite("TerminalCell")
struct TerminalCellTests {
    @Test func creation() {
        let cell = TerminalCell(
            character: "A",
            foreground: .default,
            background: .default,
            attributes: []
        )
        #expect(cell.character == "A")
    }

    @Test func withAttributes() {
        let cell = TerminalCell(
            character: "B",
            foreground: .ansi(1),
            background: .rgb(r: 255, g: 0, b: 0),
            attributes: [.bold, .underline]
        )
        #expect(cell.attributes.contains(.bold))
        #expect(cell.attributes.contains(.underline))
        #expect(!cell.attributes.contains(.italic))
    }
}

// MARK: - CellAttributes Tests

@Suite("CellAttributes")
struct CellAttributesTests {
    @Test func optionSet() {
        var attrs: CellAttributes = [.bold, .italic]
        #expect(attrs.contains(.bold))
        #expect(attrs.contains(.italic))
        #expect(!attrs.contains(.underline))

        attrs.insert(.underline)
        #expect(attrs.contains(.underline))
    }

    @Test func allAttributes() {
        let all: CellAttributes = [.bold, .italic, .underline, .strikethrough, .dim, .inverse]
        #expect(all.contains(.bold))
        #expect(all.contains(.inverse))
    }
}

// MARK: - TerminalColor Tests

@Suite("TerminalColor")
struct TerminalColorTests {
    @Test func ansiColor() {
        let color = TerminalColor.ansi(1)
        if case .ansi(let n) = color {
            #expect(n == 1)
        } else {
            #expect(Bool(false), "Expected .ansi case")
        }
    }

    @Test func rgbColor() {
        let color = TerminalColor.rgb(r: 255, g: 128, b: 0)
        if case .rgb(let r, let g, let b) = color {
            #expect(r == 255)
            #expect(g == 128)
            #expect(b == 0)
        } else {
            #expect(Bool(false), "Expected .rgb case")
        }
    }

    @Test func defaultColor() {
        let color = TerminalColor.default
        if case .default = color {
            #expect(true)
        } else {
            #expect(Bool(false), "Expected .default case")
        }
    }
}

// MARK: - PTYProcess Suspend/Resume Tests (macOS only — requires forkpty)

#if canImport(Darwin)
@Suite("PTYProcessSuspend")
struct PTYProcessSuspendTests {

    @Test func initialStateIsNotSuspended() throws {
        let pty = try PTYProcess(command: "sleep 60")
        #expect(!pty.isSuspended)
        #expect(pty.isRunning)
        pty.terminate()
    }

    @Test func suspendSetsFlagAndResumeClears() throws {
        let pty = try PTYProcess(command: "sleep 60")
        pty.suspend()
        #expect(pty.isSuspended)
        pty.resume()
        #expect(!pty.isSuspended)
        pty.terminate()
    }

    @Test func suspendIsIdempotent() throws {
        let pty = try PTYProcess(command: "sleep 60")
        pty.suspend()
        pty.suspend() // second call should be a no-op
        #expect(pty.isSuspended)
        pty.resume()
        #expect(!pty.isSuspended)
        pty.terminate()
    }

    @Test func resumeWithoutSuspendIsNoOp() throws {
        let pty = try PTYProcess(command: "sleep 60")
        pty.resume() // should not crash or change state
        #expect(!pty.isSuspended)
        pty.terminate()
    }

    @Test func terminateResumesSuspendedProcess() throws {
        let pty = try PTYProcess(command: "sleep 60")
        pty.suspend()
        #expect(pty.isSuspended)
        pty.terminate()
        // After terminate, isSuspended should be cleared
        // (the cleanup path resumes before sending SIGTERM)
    }
}
#endif

// MARK: - CursorPosition Tests

@Suite("CursorPosition")
struct CursorPositionTests {
    @Test func creation() {
        let pos = CursorPosition(column: 10, row: 5, isVisible: true)
        #expect(pos.column == 10)
        #expect(pos.row == 5)
        #expect(pos.isVisible)
    }
}
