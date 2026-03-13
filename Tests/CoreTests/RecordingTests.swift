// MARK: - Recording Engine Tests

import Testing
import Foundation
@testable import AgentsBoardCore

// MARK: - RecordingMetadata Tests

@Suite("RecordingMetadata")
struct RecordingMetadataTests {
    @Test func creation() {
        let meta = RecordingMetadata(
            sessionId: "s1", provider: "claude",
            model: "opus", project: "/test",
            startTime: Date(), endTime: nil,
            totalCost: 0.50,
            terminalWidth: 120, terminalHeight: 40
        )
        #expect(meta.sessionId == "s1")
        #expect(meta.provider == "claude")
        #expect(meta.terminalWidth == 120)
        #expect(meta.terminalHeight == 40)
        #expect(meta.totalCost == 0.50)
    }

    @Test func codable() throws {
        let meta = RecordingMetadata(
            sessionId: "s1", provider: nil,
            model: nil, project: nil,
            startTime: Date(), endTime: nil,
            totalCost: nil,
            terminalWidth: 80, terminalHeight: 24
        )
        let data = try JSONEncoder().encode(meta)
        let decoded = try JSONDecoder().decode(RecordingMetadata.self, from: data)
        #expect(decoded.sessionId == "s1")
        #expect(decoded.provider == nil)
    }
}

// MARK: - RecordingError Tests

@Suite("RecordingError")
struct RecordingErrorTests {
    @Test func noActiveRecording() {
        let error = RecordingError.noActiveRecording(sessionId: "s1")
        if case .noActiveRecording(let sid) = error {
            #expect(sid == "s1")
        } else {
            #expect(Bool(false), "Expected noActiveRecording case")
        }
    }
}

// MARK: - RecordingEngine Tests

@Suite("RecordingEngine")
struct RecordingEngineTests {
    @Test func initialState() {
        let engine = RecordingEngine()
        #expect(!engine.isRecording)
    }

    @Test func startRecording() throws {
        let engine = RecordingEngine()
        try engine.startRecording(sessionId: "test_session")
        #expect(engine.isRecording(sessionId: "test_session"))
    }

    @Test func recordData() throws {
        let engine = RecordingEngine()
        try engine.startRecording(sessionId: "test_session")
        let data = "Hello World".data(using: .utf8)!
        engine.recordData(data, forSession: "test_session")
    }

    @Test func stopRecordingReturnsURL() throws {
        let engine = RecordingEngine()
        try engine.startRecording(sessionId: "test_session")
        let url = try engine.stopRecording(sessionId: "test_session")
        #expect(!url.path.isEmpty)
    }

    @Test func stopNonexistentRecordingThrows() {
        let engine = RecordingEngine()
        #expect(throws: RecordingError.self) {
            _ = try engine.stopRecording(sessionId: "nonexistent")
        }
    }

    @Test func listRecordings() {
        let engine = RecordingEngine()
        let recordings = engine.listRecordings()
        #expect(recordings is [URL])
    }
}
