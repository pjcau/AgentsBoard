---
sidebar_position: 2
---

# Installation

## From Source

```bash
git clone https://github.com/pjcau/AgentsBoard.git
cd AgentsBoard
swift build -c release
```

The built app will be at `.build/release/AgentsBoard`.

## Using the CLI Tool

AgentsBoard includes `agentsctl`, a command-line tool for controlling sessions:

```bash
# Build the CLI
swift build --product agentsctl

# Install to /usr/local/bin
cp .build/debug/agentsctl /usr/local/bin/

# Verify
agentsctl --help
```

## Homebrew

```bash
brew tap pjcau/agentsboard
brew install --cask agentsboard
```

## Building the .app Bundle

```bash
# Build, sign, and create the .app bundle
bash build.sh && open build/AgentsBoard.app
```

## Dependencies

AgentsBoard uses Swift Package Manager. Dependencies are resolved automatically:

| Package | Purpose |
|---------|---------|
| [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) | VT100/xterm terminal emulation |
| [Yams](https://github.com/jpsim/Yams) | YAML configuration parsing |
| [GRDB.swift](https://github.com/groue/GRDB.swift) | SQLite persistence layer |

## Project Structure

```
AgentsBoard/
├── Sources/
│   ├── App/          # Main app entry point, CompositionRoot
│   ├── Core/         # Domain logic (zero UI dependencies)
│   ├── UI/           # SwiftUI + AppKit views
│   └── CLI/          # agentsctl command-line tool
├── Tests/
│   ├── CoreTests/    # 229 unit tests
│   └── UITests/      # View model tests
├── Casks/            # Homebrew cask formula
└── website/          # This documentation (Docusaurus)
```
