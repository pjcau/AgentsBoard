---
sidebar_position: 3
---

# Editor

Read-only code viewer with syntax highlighting, line numbers, and tabbed file management.

## Features

- **Syntax highlighting** for Swift, Python, JavaScript, TypeScript, Rust, Go
- **Line numbers** with monospaced font
- **Tab bar** for multiple open files
- **Modified indicator** (orange dot) for changed files
- **Line highlighting** for drawing attention to specific lines

## Syntax Highlighting

The built-in `SyntaxHighlighter` provides basic token-based highlighting:

```swift
let highlighter = SyntaxHighlighter()
let content = highlighter.highlight(source, language: "swift")
// Returns EditorContent with tokenized lines
```

### Token Types

| Token | Color | Example |
|-------|-------|---------|
| Keyword | Pink | `func`, `var`, `let` |
| String | Green | `"hello"` |
| Comment | Gray | `// comment` |
| Number | Orange | `42`, `3.14` |
| Type | Cyan | Custom types |
| Function | Yellow | Function calls |
| Property | Purple | Property access |

## Supported Languages

Swift keywords are fully supported. Other languages use generic highlighting rules.
