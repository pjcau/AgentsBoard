// MARK: - Metal Terminal View
// GPU-accelerated terminal rendering: Metal renders all terminal text and colors,
// SwiftTerm handles PTY I/O and keyboard input (transparent overlay).
//
// Architecture:
//   - MTKView (Metal): renders the full terminal grid from TerminalGridSnapshot
//   - LocalProcessTerminalView (SwiftTerm): invisible, handles PTY + input
//   - A display-link-synced bridge reads SwiftTerm's buffer → TerminalGridSnapshot → MetalRenderer

import SwiftUI
import Metal
import MetalKit
import SwiftTerm
import AgentsBoardCore

/// Returns true if Metal GPU rendering is available on this device.
func isMetalAvailable() -> Bool {
    MTLCreateSystemDefaultDevice() != nil
}

/// GPU-accelerated terminal view.
/// Metal renders the terminal cell grid; SwiftTerm is an invisible overlay for PTY + keyboard input.
struct MetalTerminalView: NSViewRepresentable {
    let command: String
    let workingDirectory: String?
    let onProcessExit: ((Int32?) -> Void)?

    @AppStorage(TerminalFontSize.appStorageKey) private var fontSize: Double = TerminalFontSize.defaultSize

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true

        guard let device = MTLCreateSystemDefaultDevice() else {
            return container
        }

        // Layer 1: Metal terminal renderer (GPU-accelerated text + colors)
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0)
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = true
        mtkView.preferredFramesPerSecond = 60
        mtkView.autoresizingMask = [.width, .height]

        if let renderer = MetalRenderer(device: device) {
            // Build glyph atlas with current font size
            renderer.updateGlyphAtlas(fontFamily: "SF Mono", fontSize: fontSize)
            mtkView.delegate = context.coordinator
            context.coordinator.renderer = renderer
            context.coordinator.mtkView = mtkView
        }

        container.addSubview(mtkView)

        // Layer 2: SwiftTerm terminal (invisible — handles PTY + keyboard input only)
        let termView = NotifyingTerminalView(frame: .zero)
        termView.processDelegate = context.coordinator
        termView.onChangeTarget = context.coordinator
        termView.notifyUpdateChanges = true
        termView.autoresizingMask = [.width, .height]

        // SwiftTerm renders text (full unicode + colors), Metal renders cell backgrounds via GPU
        termView.nativeBackgroundColor = NSColor.clear
        termView.nativeForegroundColor = .green

        // Apply font for correct cell size calculations (even though SwiftTerm won't render)
        if let monoFont = NSFont(name: "SF Mono", size: fontSize)
            ?? NSFont.userFixedPitchFont(ofSize: fontSize) {
            termView.font = monoFont
        }

        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        var env: [String] = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
        env.removeAll { $0.hasPrefix("TERM=") }
        env.append("TERM=xterm-256color")
        if !env.contains(where: { $0.hasPrefix("LANG=") }) {
            env.append("LANG=en_US.UTF-8")
        }

        // Defer process start so SwiftTerm has a real frame for correct cols/rows
        context.coordinator.pendingStart = (shell, command, env, workingDirectory)
        context.coordinator.termView = termView

        DispatchQueue.main.async {
            guard let pending = context.coordinator.pendingStart else { return }
            context.coordinator.pendingStart = nil
            termView.startProcess(
                executable: pending.shell,
                args: ["-l", "-c", pending.command],
                environment: pending.env,
                currentDirectory: pending.workDir
            )
        }

        container.addSubview(termView)

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Update glyph atlas if font size changed
        context.coordinator.renderer?.updateGlyphAtlas(fontFamily: "SF Mono", fontSize: fontSize)

        // Update SwiftTerm font for correct cell sizing
        if let termView = context.coordinator.termView,
           let monoFont = NSFont(name: "SF Mono", size: fontSize)
            ?? NSFont.userFixedPitchFont(ofSize: fontSize) {
            if termView.font.pointSize != monoFont.pointSize {
                termView.font = monoFont
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onProcessExit: onProcessExit)
    }

    // MARK: - Coordinator (MTKViewDelegate + SwiftTerm bridge)

    /// Subclass of LocalProcessTerminalView that notifies when terminal content changes,
    /// enabling on-demand Metal rendering instead of continuous 60fps redraw.
    class NotifyingTerminalView: LocalProcessTerminalView {
        weak var onChangeTarget: Coordinator?

        override func rangeChanged(source: TerminalView, startY: Int, endY: Int) {
            super.rangeChanged(source: source, startY: startY, endY: endY)
            onChangeTarget?.terminalContentDidChange()
        }
    }

    class Coordinator: NSObject, MTKViewDelegate, LocalProcessTerminalViewDelegate {
        var renderer: MetalRenderer?
        weak var mtkView: MTKView?
        weak var termView: LocalProcessTerminalView?
        var pendingStart: (shell: String, command: String, env: [String], workDir: String?)?
        let onProcessExit: ((Int32?) -> Void)?
        private var previousGridHash: Int = 0
        private var needsRedraw = true

        init(onProcessExit: ((Int32?) -> Void)?) {
            self.onProcessExit = onProcessExit
        }

        func terminalContentDidChange() {
            needsRedraw = true
            mtkView?.setNeedsDisplay(mtkView?.bounds ?? .zero)
        }

        // MARK: - MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let renderer, let termView else {
                // No terminal yet — render empty frame
                renderer?.render(viewports: [])
                renderer?.draw(in: view)
                return
            }

            // Extract SwiftTerm's buffer into a TerminalGridSnapshot
            let terminal = termView.getTerminal()
            let cols = terminal.cols
            let rows = terminal.rows

            guard cols > 0, rows > 0 else {
                renderer.render(viewports: [])
                renderer.draw(in: view)
                return
            }

            let snapshot = Self.extractGrid(from: terminal, cols: cols, rows: rows)

            // Skip render if grid content hasn't changed (byte-level hash)
            let gridHash = snapshot.cells.withUnsafeBufferPointer { buf -> Int in
                let raw = UnsafeRawBufferPointer(buf)
                var hasher = Hasher()
                hasher.combine(bytes: raw)
                return hasher.finalize()
            }
            guard gridHash != previousGridHash else { return }
            previousGridHash = gridHash

            // Build cursor position
            let cursorCol = terminal.buffer.x
            let cursorRow = terminal.buffer.y
            let cursor = CursorPosition(column: cursorCol, row: cursorRow, isVisible: true)

            // Build viewport covering the full drawable
            let drawableSize = view.drawableSize
            let viewport = TerminalViewportData(
                sessionId: "metal-terminal",
                rect: ViewportRect(
                    x: 0,
                    y: 0,
                    width: Double(drawableSize.width),
                    height: Double(drawableSize.height)
                ),
                grid: snapshot,
                cursorPosition: cursor,
                isFocused: true
            )

            renderer.render(viewports: [viewport])
            renderer.draw(in: view)
        }

        // MARK: - SwiftTerm Buffer → TerminalGridSnapshot

        /// Reads SwiftTerm's terminal buffer and converts to our TerminalGridSnapshot.
        /// Called every frame (~60fps) — optimized for minimal allocations.
        static func extractGrid(from terminal: Terminal, cols: Int, rows: Int) -> TerminalGridSnapshot {
            var cells = [TerminalCell]()
            cells.reserveCapacity(cols * rows)

            for row in 0..<rows {
                guard let line = terminal.getLine(row: row) else {
                    // Fill missing rows with spaces
                    let emptyCell = TerminalCell(
                        codepoint: 0x20,
                        foreground: TerminalColor.default.packed,
                        background: TerminalColor.default.packed,
                        attributesRaw: 0
                    )
                    cells.append(contentsOf: repeatElement(emptyCell, count: cols))
                    continue
                }

                for col in 0..<cols {
                    let charData = line[col]

                    // Use getCharacter() since code/maxRune are internal to SwiftTerm
                    let char = charData.getCharacter()
                    let codepoint = char.unicodeScalars.first?.value ?? 0x20

                    // Convert SwiftTerm colors → packed TerminalColor
                    let fg = Self.convertColor(charData.attribute.fg)
                    let bg = Self.convertColor(charData.attribute.bg)

                    // Convert style attributes
                    let style = charData.attribute.style
                    var attrs: UInt8 = 0
                    if style.contains(.bold)      { attrs |= CellAttributes.bold.rawValue }
                    if style.contains(.italic)     { attrs |= CellAttributes.italic.rawValue }
                    if style.contains(.underline)  { attrs |= CellAttributes.underline.rawValue }
                    if style.contains(.crossedOut) { attrs |= CellAttributes.strikethrough.rawValue }
                    if style.contains(.dim)        { attrs |= CellAttributes.dim.rawValue }
                    if style.contains(.inverse)    { attrs |= CellAttributes.inverse.rawValue }

                    cells.append(TerminalCell(
                        codepoint: codepoint,
                        foreground: fg,
                        background: bg,
                        attributesRaw: attrs
                    ))
                }
            }

            return TerminalGridSnapshot(columns: cols, rows: rows, cells: cells)
        }

        /// Converts SwiftTerm's Attribute.Color to our packed TerminalColor UInt32.
        static func convertColor(_ color: Attribute.Color) -> UInt32 {
            switch color {
            case .ansi256(let code):
                return TerminalColor.ansi(code).packed
            case .trueColor(let r, let g, let b):
                return TerminalColor.rgb(r: r, g: g, b: b).packed
            case .defaultColor, .defaultInvertedColor:
                return TerminalColor.default.packed
            }
        }

        // MARK: - LocalProcessTerminalViewDelegate

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            DispatchQueue.main.async { [weak self] in
                self?.onProcessExit?(exitCode)
            }
        }
    }
}
