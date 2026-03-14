// MARK: - Metal Terminal View
// NSViewRepresentable wrapping MTKView + MetalRenderer for GPU-accelerated terminal display.
// Falls back to SwiftTerm (TerminalEmulatorView) if Metal is unavailable.

import SwiftUI
import MetalKit
import AgentsBoardCore

/// SwiftUI wrapper for MetalRenderer + MTKView.
/// Provides a GPU-accelerated terminal background for session cards.
struct MetalTerminalView: NSViewRepresentable {
    let command: String
    let workingDirectory: String?
    let onProcessExit: ((Int32?) -> Void)?

    func makeNSView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            // Should never reach here — caller checks Metal availability
            return MTKView()
        }

        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0)
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60

        if let renderer = MetalRenderer(device: device) {
            mtkView.delegate = renderer
            context.coordinator.renderer = renderer
        }

        // Launch the process via PTY (same as SwiftTerm path)
        context.coordinator.launchProcess(
            command: command,
            workingDirectory: workingDirectory,
            renderer: context.coordinator.renderer,
            onExit: onProcessExit
        )

        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var renderer: MetalRenderer?
        private var ptyProcess: PTYProcess?
        private var readSource: DispatchSourceRead?

        func launchProcess(
            command: String,
            workingDirectory: String?,
            renderer: MetalRenderer?,
            onExit: ((Int32?) -> Void)?
        ) {
            let pty = PTYProcess()
            self.ptyProcess = pty

            let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
            var env = ProcessInfo.processInfo.environment
            env["TERM"] = "xterm-256color"
            if env["LANG"] == nil { env["LANG"] = "en_US.UTF-8" }

            do {
                try pty.spawn(
                    executable: shell,
                    args: [shell, "-l", "-c", command],
                    environment: env.map { "\($0.key)=\($0.value)" },
                    workingDirectory: workingDirectory
                )
            } catch {
                return
            }

            // Read PTY output and feed to renderer as a simple grid
            guard pty.fileDescriptor >= 0 else { return }
            let fd = pty.fileDescriptor
            let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: .global(qos: .userInteractive))
            source.setEventHandler { [weak self] in
                var buffer = [UInt8](repeating: 0, count: 4096)
                let bytesRead = read(fd, &buffer, buffer.count)
                if bytesRead <= 0 {
                    source.cancel()
                    DispatchQueue.main.async {
                        onExit?(self?.ptyProcess?.pid.flatMap { pid in
                            var status: Int32 = 0
                            waitpid(pid, &status, WNOHANG)
                            return status
                        })
                    }
                }
                // Note: Full VT parsing would go here to build TerminalGridSnapshot.
                // For now, Metal renders the background grid; SwiftTerm handles real TUI.
            }
            source.setCancelHandler { [weak self] in
                self?.readSource = nil
            }
            source.resume()
            self.readSource = source
        }

        deinit {
            readSource?.cancel()
        }
    }
}

/// Returns true if Metal GPU rendering is available on this device.
func isMetalAvailable() -> Bool {
    MTLCreateSystemDefaultDevice() != nil
}
