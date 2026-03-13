// MARK: - Recording Engine (Step 15.1)
// Asciicast v2 session recording with metadata.

import Foundation
import Observation

/// Recording errors.
public enum RecordingError: Error {
    case noActiveRecording(sessionId: String)
}

/// Metadata for a recording.
public struct RecordingMetadata: Codable {
    public let sessionId: String
    public let provider: String?
    public let model: String?
    public let project: String?
    public let startTime: Date
    public var endTime: Date?
    public var totalCost: Decimal?
    public let terminalWidth: Int
    public let terminalHeight: Int

    public init(sessionId: String, provider: String?, model: String?, project: String?, startTime: Date, endTime: Date?, totalCost: Decimal?, terminalWidth: Int, terminalHeight: Int) {
        self.sessionId = sessionId
        self.provider = provider
        self.model = model
        self.project = project
        self.startTime = startTime
        self.endTime = endTime
        self.totalCost = totalCost
        self.terminalWidth = terminalWidth
        self.terminalHeight = terminalHeight
    }
}

/// Asciicast v2 writer.
final class AsciicastWriter {
    private let fileHandle: FileHandle
    private let startTime: Date

    init(filePath: String, width: Int, height: Int, metadata: RecordingMetadata) throws {
        FileManager.default.createFile(atPath: filePath, contents: nil)
        self.fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: filePath))
        self.startTime = metadata.startTime

        // Write header
        let header: [String: Any] = [
            "version": 2,
            "width": width,
            "height": height,
            "timestamp": Int(metadata.startTime.timeIntervalSince1970),
            "title": "AgentsBoard Recording",
            "env": ["TERM": "xterm-256color", "SHELL": "/bin/zsh"]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: header),
           let json = String(data: data, encoding: .utf8) {
            fileHandle.write((json + "\n").data(using: .utf8)!)
        }
    }

    func writeOutput(_ data: Data) {
        let elapsed = Date().timeIntervalSince(startTime)
        guard let text = String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t") else { return }

        let line = "[\(String(format: "%.6f", elapsed)), \"o\", \"\(text)\"]\n"
        if let lineData = line.data(using: .utf8) {
            fileHandle.write(lineData)
        }
    }

    func writeInput(_ data: Data) {
        let elapsed = Date().timeIntervalSince(startTime)
        guard let text = String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") else { return }

        let line = "[\(String(format: "%.6f", elapsed)), \"i\", \"\(text)\"]\n"
        if let lineData = line.data(using: .utf8) {
            fileHandle.write(lineData)
        }
    }

    func close() {
        fileHandle.closeFile()
    }

    deinit { close() }
}

/// Manages recording lifecycle for sessions.
@Observable
public final class RecordingEngine: SessionRecordable {

    private var activeRecordings: [String: AsciicastWriter] = [:]
    private let recordingsDir: URL

    public init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        recordingsDir = support.appendingPathComponent("AgentsBoard/recordings")
        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
    }

    private var recordingPaths: [String: URL] = [:]

    public var isRecording: Bool { !activeRecordings.isEmpty }

    public func startRecording(sessionId: String) throws {
        let width = 120
        let height = 40
        let filename = "\(sessionId)_\(ISO8601DateFormatter().string(from: Date())).cast"
            .replacingOccurrences(of: ":", with: "-")
        let fileURL = recordingsDir.appendingPathComponent(filename)
        let filePath = fileURL.path

        let metadata = RecordingMetadata(
            sessionId: sessionId, provider: nil, model: nil,
            project: nil, startTime: Date(), endTime: nil, totalCost: nil,
            terminalWidth: width, terminalHeight: height
        )

        let writer = try AsciicastWriter(filePath: filePath, width: width, height: height, metadata: metadata)
        activeRecordings[sessionId] = writer
        recordingPaths[sessionId] = fileURL
    }

    public func startRecording(sessionId: String, width: Int, height: Int,
                        provider: String?, model: String?) throws {
        let filename = "\(sessionId)_\(ISO8601DateFormatter().string(from: Date())).cast"
            .replacingOccurrences(of: ":", with: "-")
        let fileURL = recordingsDir.appendingPathComponent(filename)
        let filePath = fileURL.path

        let metadata = RecordingMetadata(
            sessionId: sessionId, provider: provider, model: model,
            project: nil, startTime: Date(), endTime: nil, totalCost: nil,
            terminalWidth: width, terminalHeight: height
        )

        let writer = try AsciicastWriter(filePath: filePath, width: width, height: height, metadata: metadata)
        activeRecordings[sessionId] = writer
        recordingPaths[sessionId] = fileURL
    }

    public func stopRecording(sessionId: String) throws -> URL {
        activeRecordings[sessionId]?.close()
        activeRecordings.removeValue(forKey: sessionId)
        guard let url = recordingPaths.removeValue(forKey: sessionId) else {
            throw RecordingError.noActiveRecording(sessionId: sessionId)
        }
        return url
    }

    public func recordData(_ data: Data, forSession sessionId: String) {
        activeRecordings[sessionId]?.writeOutput(data)
    }

    public func recordOutput(sessionId: String, data: Data) {
        activeRecordings[sessionId]?.writeOutput(data)
    }

    public func recordInput(sessionId: String, data: Data) {
        activeRecordings[sessionId]?.writeInput(data)
    }

    public func isRecording(sessionId: String) -> Bool {
        activeRecordings[sessionId] != nil
    }

    public func listRecordings() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: recordingsDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles)) ?? []
    }

    public func deleteRecording(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
