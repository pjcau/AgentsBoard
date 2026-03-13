---
sidebar_position: 2
---

# Diff Review

Side-by-side and unified diff viewer for reviewing agent file changes.

## View Modes

- **Unified** — traditional unified diff with line numbers and color coding
- **Side by Side** — old and new versions displayed in parallel

## Features

- Line numbers for both old and new files
- Addition/deletion counts in the toolbar
- Approve/Reject buttons for quick review
- Color-coded lines: green for additions, red for deletions

## Diff Parser

The built-in parser handles standard unified diff format:

```swift
let parser = DiffParser()
let hunks = parser.parse(unifiedDiff: diffString)
// Returns [DiffHunk] with typed DiffLine entries
```

## Line Types

```swift
enum DiffLineType {
    case context    // Unchanged line
    case addition   // New line (+)
    case deletion   // Removed line (-)
    case header     // Hunk header (@@)
}
```
