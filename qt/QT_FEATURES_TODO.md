# Qt Desktop — Feature Parity with SwiftUI macOS App

## Current Qt Status
- ✅ Main window with sidebar + content area
- ✅ Fleet overview grid with session cards
- ✅ New session dialog (name, command, workdir + folder picker)
- ✅ TerminalWidget C++ with PTY callbacks
- ✅ System tray icon
- ❌ Terminal not embedded in cards — opens fullscreen separately
- ❌ Terminal doesn't receive keyboard focus
- ❌ No tabs in session cards
- ❌ No real PTY process launch

---

## Phase 1 — CRITICAL (app must work)

### 1.1 Terminal embedded in session cards (NOT fullscreen)
- Session card should contain a mini terminal preview
- Click on card → card expands or shows terminal in content area (split: sidebar + session detail)
- "← Back" button returns to fleet grid
- **Current bug**: terminal takes over entire window with no way to interact

### 1.2 TerminalWidget must receive keyboard input
- `forceActiveFocus()` on click AND on session selection
- `mousePressEvent` must call `forceActiveFocus()`
- Verify `keyPressEvent` actually sends to PTY

### 1.3 PTY process must actually launch
- `ab_session_create()` in CoreFFI must fork a real PTY with the command
- Verify `claude` (or whatever command) actually starts as a child process
- Terminal output callback must feed data back to TerminalWidget

### 1.4 Session detail view (when clicking a card)
- Layout: sidebar stays visible, content area shows session detail
- Session detail has: header bar (back + session name + state) + terminal (fills rest)
- Terminal gets focus automatically

---

## Phase 2 — Session Card Tabs (match SwiftUI)

### 2.1 Tab bar in session detail view
- 4 tabs: Terminal | Activity | Info | Files
- Terminal tab is default
- Terminal stays alive when switching tabs (hidden, not destroyed)

### 2.2 Info tab
- Provider, model, state
- Session name, ID, command, duration, cost
- Working directory, git branch

### 2.3 Activity tab
- Timeline of session events
- Timestamp + icon + event type + description

### 2.4 Files tab
- File tree browser for session working directory

---

## Phase 3 — Sidebar Improvements

### 3.1 Session list items show more info
- State dot + name + provider pill
- Git branch (if available)
- Project path (shortened)
- Uptime/duration

### 3.2 Context menu on session items
- Edit / Archive / Delete / Copy ID
- Move Up / Move Down

### 3.3 Search/filter bar at top of sidebar

---

## Phase 4 — Fleet Overview Improvements

### 4.1 Fleet header metrics bar
- Total sessions, active, needs input, errors, total cost

### 4.2 Filter bar
- Filter by provider (Claude/Codex/Aider/Gemini)
- Filter by state (working/needsInput/error/inactive)

### 4.3 Session cards show richer info
- State dot + name + model badge
- Cost + duration
- Last action text
- State-colored border

---

## Phase 5 — Layout Modes

### 5.1 Layout selector
- Single (1 card fullscreen)
- List (vertical stack)
- 2-Column grid
- 3-Column grid
- Fleet (auto-fitting grid) — current default

### 5.2 Keyboard shortcuts
- Cmd+1 through Cmd+5 for layouts

---

## Phase 6 — Advanced Features

### 6.1 Command Palette (Cmd+K)
### 6.2 Bottom terminal panel (Cmd+T)
### 6.3 Settings panel (font size, appearance)
### 6.4 Session edit dialog
### 6.5 Diff review window
### 6.6 Session remix (fork to worktree)
### 6.7 Clone & Launch from Git URL
### 6.8 Smart Mode (AI task routing)
