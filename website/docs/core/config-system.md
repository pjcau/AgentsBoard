---
sidebar_position: 5
---

# Configuration System

Three-level configuration cascade with hot-reload support.

## Config Cascade

```
Project Config  →  overrides  →  User Config  →  overrides  →  Defaults
(.agentsboard.yml)              (~/.agentsboard/)              (built-in)
```

## AppConfig

```swift
public struct AppConfig {
    var theme: String
    var fontFamily: String
    var fontSize: CGFloat
    var notifications: Bool
    var scrollback: Int
    var layout: LayoutMode
    var menuBarMode: Bool
    var notificationSounds: Bool
    var terminalNewlineMode: NewlineMode
}
```

## Layout Modes

```swift
public enum LayoutMode {
    case single       // One session, full screen
    case list         // Vertical list of sessions
    case twoColumn    // Two sessions side by side
    case threeColumn  // Three column layout
    case fleet        // Grid overview of all sessions
}
```

## Project Configuration

Per-project YAML configuration:

```yaml
# .agentsboard.yml
name: MyApp
sessions:
  - name: Backend
    command: claude --project backend
    workdir: ./backend
    autoStart: true
    restart: onFailure
    env:
      CLAUDE_MODEL: opus

  - name: Frontend
    command: aider
    workdir: ./frontend
    autoStart: false
    restart: never
```

## Hot Reload

The `ConfigManager` watches configuration files for changes using file system events:

```swift
let config = ConfigManager(yamlParser: yamlParser)
config.onConfigChange = { newConfig in
    // React to config changes without restart
    applyTheme(newConfig.theme)
}
config.startWatching()
```
