// MARK: - Recording Protocols

import Foundation

/// Records a terminal session in asciicast v2 format.
public protocol SessionRecordable: AnyObject {
    var isRecording: Bool { get }

    func startRecording(sessionId: String) throws
    func stopRecording(sessionId: String) throws -> URL
    func recordData(_ data: Data, forSession sessionId: String)
}

/// Plays back a recorded session.
public protocol SessionPlayable: AnyObject {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var totalDuration: TimeInterval { get }
    var playbackSpeed: Double { get set }

    func load(from url: URL) throws
    func play()
    func pause()
    func seek(to time: TimeInterval)

    var onData: ((Data) -> Void)? { get set }
    var onComplete: (() -> Void)? { get set }
}
