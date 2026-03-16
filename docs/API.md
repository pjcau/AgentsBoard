# AgentsBoard HTTP API Reference

Base URL: `http://localhost:19850/api/v1`

## Health

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Server health check |

## Sessions

| Method | Path | Description |
|--------|------|-------------|
| GET | `/sessions` | List all sessions |
| GET | `/sessions/:id` | Get session by ID |
| POST | `/sessions/:id/input` | Send text input to session |
| POST | `/sessions/:id/archive` | Archive a session |
| DELETE | `/sessions/:id` | Delete a session |
| GET | `/sessions/:id/output` | Get terminal output (query: `?lines=500`) |

### POST /sessions/:id/input

```json
{ "text": "yes" }
```

## Fleet

| Method | Path | Description |
|--------|------|-------------|
| GET | `/fleet/stats` | Fleet-wide statistics |

### Response

```json
{
  "totalSessions": 5,
  "activeSessions": 3,
  "needsInputCount": 1,
  "errorCount": 0,
  "totalCost": "1.42",
  "costByProvider": { "claude": "1.20", "codex": "0.22" },
  "sessionsByState": { "working": 3, "needsInput": 1, "inactive": 1 }
}
```

## Activity

| Method | Path | Description |
|--------|------|-------------|
| GET | `/activity` | Activity log (query: `?limit=100&session=<id>`) |

## Costs

| Method | Path | Description |
|--------|------|-------------|
| GET | `/costs` | Fleet total cost |
| GET | `/costs/session/:id` | Session cost |
| GET | `/costs/history` | Cost history (query: `?from=<ISO8601>&to=<ISO8601>`) |

## Config

| Method | Path | Description |
|--------|------|-------------|
| GET | `/config` | Current app configuration |
| GET | `/themes` | Available themes |
| PUT | `/themes` | Set active theme |

### PUT /themes

```json
{ "name": "Nord" }
```

## WebSocket

Connect to `ws://localhost:19850/ws` for real-time events.

### Channels

| Channel | Events |
|---------|--------|
| `fleet` | `fleet_updated` — session list changed |
| `session:{id}` | `state_changed`, `output` — per-session events |
| `activity` | `new_activity` — new activity event |
| `costs` | `cost_updated` — cost totals changed |

### Event Format

```json
{
  "channel": "fleet",
  "event": "fleet_updated",
  "data": [...],
  "timestamp": "2026-03-16T10:00:00Z"
}
```

### Terminal Streaming

WebSocket at `/api/v1/sessions/:id/terminal/stream`:
- Server → Client: base64-encoded PTY output
- Client → Server: raw keystroke data
