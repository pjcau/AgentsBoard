// MARK: - Metal Terminal View
// Composite view: MTKView (Metal background) + SwiftTerm overlay for terminal interaction.
// The Metal layer provides GPU-accelerated background rendering.
// SwiftTerm handles all terminal input/output and TUI rendering.
// Falls back to TerminalEmulatorView (SwiftTerm-only) if Metal is unavailable.

import SwiftUI
import Metal
import MetalKit
import SwiftTerm
import AgentsBoardCore

/// Returns true if Metal GPU rendering is available on this device.
func isMetalAvailable() -> Bool {
    MTLCreateSystemDefaultDevice() != nil
}

/// Composite Metal + SwiftTerm terminal view.
/// Metal renders the GPU-accelerated background; SwiftTerm renders the terminal content on top.
struct MetalTerminalView: NSViewRepresentable {
    let command: String
    let workingDirectory: String?
    let onProcessExit: ((Int32?) -> Void)?

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true

        guard let device = MTLCreateSystemDefaultDevice() else {
            return container
        }

        // Layer 1: Metal background (GPU-accelerated grid)
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0)
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.autoresizingMask = [.width, .height]

        if let renderer = MetalRenderer(device: device) {
            mtkView.delegate = renderer
            context.coordinator.renderer = renderer
        }

        container.addSubview(mtkView)

        // Layer 2: SwiftTerm terminal (input + TUI rendering)
        let termView = LocalProcessTerminalView(frame: .zero)
        termView.processDelegate = context.coordinator
        termView.nativeBackgroundColor = NSColor.black.withAlphaComponent(0.0)
        termView.nativeForegroundColor = .green
        termView.autoresizingMask = [.width, .height]

        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        var env: [String] = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
        env.removeAll { $0.hasPrefix("TERM=") }
        env.append("TERM=xterm-256color")
        if !env.contains(where: { $0.hasPrefix("LANG=") }) {
            env.append("LANG=en_US.UTF-8")
        }

        termView.startProcess(
            executable: shell,
            args: ["-l", "-c", command],
            environment: env,
            currentDirectory: workingDirectory
        )

        container.addSubview(termView)

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onProcessExit: onProcessExit)
    }

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var renderer: MetalRenderer?
        let onProcessExit: ((Int32?) -> Void)?

        init(onProcessExit: ((Int32?) -> Void)?) {
            self.onProcessExit = onProcessExit
        }

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
