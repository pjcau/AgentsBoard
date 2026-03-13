---
sidebar_position: 1
---

# agentsctl CLI

Command-line tool for controlling AgentsBoard from the terminal.

## Installation

```bash
swift build --product agentsctl
cp .build/debug/agentsctl /usr/local/bin/
```

## Commands

### list

List all active sessions:

```bash
agentsctl list
# ID          PROVIDER  STATE      COST    PROJECT
# abc-123     claude    working    $0.45   /path/to/project
# def-456     codex     needsInput $0.12   /path/to/other
```

### status

Show fleet overview:

```bash
agentsctl status
# Fleet Status
# ─────────────────────────
# Total Sessions: 5
# Active:         3
# Needs Input:    1
# Errors:         0
# Total Cost:     $12.30
```

### states

Show agent states:

```bash
agentsctl states
# abc-123: working (Claude Opus)
# def-456: needsInput (Codex GPT-4)
```

### send

Send input to a session:

```bash
agentsctl send abc-123 "approve the changes"
```

### log

Show activity log:

```bash
agentsctl log
agentsctl log --session abc-123
agentsctl log --limit 20
```

### cost

Show cost breakdown:

```bash
agentsctl cost
# Provider    Cost
# ──────────────────
# Claude      $8.50
# Codex       $3.80
# Total       $12.30
```

## Communication

`agentsctl` communicates with the running AgentsBoard app via a Unix socket at:
```
/tmp/agentsboard.sock
```
