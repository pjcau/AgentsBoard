---
sidebar_position: 2
---

# Terminal Engine

The terminal engine provides PTY management, VT100 parsing, and Metal GPU rendering.

## Components

### PTYProcess
Low-level PTY management using `forkpty()`:

- Spawns child processes with pseudo-terminal
- Manages file descriptors for I/O
- Handles process termination and exit codes

### PTYMultiplexer
Single-threaded I/O multiplexing using **kqueue** (macOS kernel event notification):

- Monitors multiple PTY file descriptors on a single thread
- Dispatches data to the correct session
- Scales to dozens of concurrent sessions

### VTParser
Wraps SwiftTerm for VT100/xterm escape sequence parsing:

- Processes raw PTY output into structured terminal state
- Extracts cursor position, cell contents, colors, attributes
- Provides `TerminalGridSnapshot` for rendering

### TerminalGrid
Circular scroll buffer for terminal content:

- Efficient scrollback with configurable history
- Supports resize operations
- Produces snapshots for the Metal renderer

## TerminalSession

The `TerminalSession` class combines all components:

```swift
let session = TerminalSession()
try session.launch(command: "/bin/zsh", workingDirectory: "~/project")
session.sendInput("echo hello\n".data(using: .utf8)!)
session.resize(columns: 120, rows: 40)
```

## Metal Rendering

The rendering pipeline uses Metal for GPU-accelerated terminal display:

| Component | Purpose |
|-----------|---------|
| `GlyphAtlas` | Rasterizes font glyphs into a texture atlas |
| `TerminalRenderer` | Renders grid snapshots with viewport scissoring |
| Triple-buffered vertices | Eliminates frame drops during updates |
| Viewport scissoring | Single MTKView renders multiple sessions |

## Data Types

```swift
public struct TerminalCell {
    let character: Character
    let foreground: TerminalColor
    let background: TerminalColor
    let attributes: CellAttributes  // bold, italic, underline, etc.
}

public enum TerminalColor {
    case ansi(UInt8)
    case rgb(r: UInt8, g: UInt8, b: UInt8)
    case `default`
}
```
