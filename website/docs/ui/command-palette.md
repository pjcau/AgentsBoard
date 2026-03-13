---
sidebar_position: 1
---

# Command Palette

Cmd+K spotlight-style command palette with fuzzy search, category filtering, and keyboard navigation.

## Features

- **Fuzzy matching** — type partial words to find commands
- **Category tabs** — filter by Session, Navigation, Layout, Theme, Fleet, General
- **Keyboard navigation** — arrow keys + Enter to execute
- **Shortcuts display** — shows keyboard shortcuts for each command

## Commands Registration (OCP)

```swift
// Register individual commands
registry.register(command: PaletteCommand(
    id: "new-session",
    title: "New Session",
    subtitle: "Start a new agent session",
    icon: "plus.circle",
    category: .session,
    shortcut: "⌘N",
    action: { startNewSession() }
))

// Or register a provider for batch commands
registry.register(provider: MyCommandProvider())
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘K` | Toggle command palette |
| `↑ / ↓` | Navigate results |
| `↩` | Execute selected |
| `Esc` | Dismiss |
