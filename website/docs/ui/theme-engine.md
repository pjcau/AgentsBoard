---
sidebar_position: 6
---

# Theme Engine

Terminal theme management with built-in themes and custom theme support.

## Built-in Themes

| Theme | Description |
|-------|-------------|
| Dark | Default dark theme |
| Light | Clean light theme |
| Solarized Dark | Solarized color scheme |
| Monokai | Monokai Pro inspired |
| Nord | Nord color palette |

## Theme Structure

```swift
public struct TerminalTheme {
    let name: String
    let author: String
    let background: ThemeColor
    let foreground: ThemeColor
    let cursor: ThemeColor
    let selection: ThemeColor
    let ansi: ANSIColors  // All 16 ANSI colors
}
```

## ThemeColor

Supports hex initialization and conversion to NSColor/SIMD4:

```swift
let color = ThemeColor(hex: "#A78BFA")
let nsColor = color.nsColor      // For AppKit
let simd = color.simd4           // For Metal shaders
```

## Custom Themes

```swift
let engine = ThemeEngine()
engine.addCustomTheme(myTheme)
try engine.loadTheme(named: "my-custom-theme")
```

## Hot Reload

Theme changes are reflected immediately through `@Observable`:

```swift
engine.onThemeChange = { newTheme in
    // Re-render terminal with new colors
}
```
