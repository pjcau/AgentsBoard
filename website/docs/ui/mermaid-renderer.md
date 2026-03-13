---
sidebar_position: 5
---

# Mermaid Renderer

Renders Mermaid diagrams from agent output using an embedded WKWebView.

## Features

- Automatic detection of ` ```mermaid ` blocks in agent output
- Four themes: Default, Dark, Forest, Neutral
- Export to PNG
- Error display for invalid diagram syntax

## Themes

```swift
enum MermaidTheme: String {
    case default_ = "default"
    case dark
    case forest
    case neutral
}
```

## Usage

The view model extracts Mermaid blocks from markdown:

```swift
let vm = MermaidRendererViewModel()
vm.loadFromOutput(agentMarkdownOutput)
// Automatically extracts ```mermaid blocks and renders them
```

## Supported Diagram Types

All Mermaid.js diagram types are supported:
- Flowcharts
- Sequence diagrams
- Class diagrams
- State diagrams
- Gantt charts
- Pie charts
- Git graphs
