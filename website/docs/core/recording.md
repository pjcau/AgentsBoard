---
sidebar_position: 6
---

# Session Recording

Record and replay agent sessions in Asciicast v2 format.

## Recording

```swift
let engine = RecordingEngine()

// Start recording a session
try engine.startRecording(sessionId: "s1")

// Feed terminal data as it arrives
engine.recordData(data, forSession: "s1")

// Stop and get the recording file
let url = try engine.stopRecording(sessionId: "s1")
// → ~/Library/Application Support/AgentsBoard/recordings/s1-<timestamp>.cast
```

## Asciicast v2 Format

Each recording is a JSONL file:

```json
{"version": 2, "width": 120, "height": 40, "timestamp": 1710000000}
[0.5, "o", "$ claude --model opus\r\n"]
[1.2, "o", "Claude Code is ready.\r\n"]
[3.0, "i", "fix the auth bug\r\n"]
```

## Metadata

```swift
public struct RecordingMetadata: Codable {
    let sessionId: String
    let provider: String?
    let model: String?
    let project: String?
    let startTime: Date
    var endTime: Date?
    var totalCost: Decimal?
    let terminalWidth: Int
    let terminalHeight: Int
}
```

## Playback

The `PlaybackView` provides a full playback interface:

- Variable speed (0.5x, 1x, 2x, 4x)
- Timeline with seek
- Event markers for key moments
- Recording browser for past sessions

## File Management

```swift
engine.listRecordings()           // List all recordings
engine.deleteRecording(at: url)   // Delete a recording
engine.isRecording(sessionId:)    // Check if session is being recorded
```
