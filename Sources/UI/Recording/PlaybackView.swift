// MARK: - Playback View (Step 15.2)
// Viewer for recorded session playback with timeline controls.

import SwiftUI
import AgentsBoardCore

struct PlaybackView: View {
    @Bindable var viewModel: PlaybackViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(viewModel.recordingName)
                    .font(.headline)
                Spacer()
                if let provider = viewModel.provider {
                    Text(provider)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)

            Divider()

            // Terminal playback area
            ZStack {
                Color(nsColor: .textBackgroundColor)
                Text(viewModel.currentFrame)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(8)
            }

            Divider()

            // Playback controls
            VStack(spacing: 8) {
                // Timeline with markers
                PlaybackTimeline(
                    progress: $viewModel.progress,
                    markers: viewModel.markers,
                    duration: viewModel.totalDuration
                )

                HStack(spacing: 16) {
                    // Time display
                    Text(viewModel.currentTimeString)
                        .font(.system(.caption, design: .monospaced))
                        .frame(width: 60)

                    // Controls
                    Button { viewModel.skipBackward() } label: {
                        Image(systemName: "gobackward.10")
                    }
                    .buttonStyle(.borderless)

                    Button { viewModel.togglePlay() } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)

                    Button { viewModel.skipForward() } label: {
                        Image(systemName: "goforward.10")
                    }
                    .buttonStyle(.borderless)

                    // Speed control
                    Picker("Speed", selection: $viewModel.speed) {
                        Text("0.5x").tag(PlaybackSpeed.half)
                        Text("1x").tag(PlaybackSpeed.normal)
                        Text("2x").tag(PlaybackSpeed.double)
                        Text("4x").tag(PlaybackSpeed.quad)
                    }
                    .frame(maxWidth: 100)

                    Spacer()

                    // Duration
                    Text(viewModel.totalDurationString)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Playback Timeline

struct PlaybackTimeline: View {
    @Binding var progress: Double
    let markers: [TimelineMarker]
    let duration: TimeInterval

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(.quaternary)
                    .frame(height: 4)

                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(.blue)
                    .frame(width: geo.size.width * progress, height: 4)

                // Markers
                ForEach(markers) { marker in
                    let x = geo.size.width * (marker.time / duration)
                    Circle()
                        .fill(marker.color)
                        .frame(width: 8, height: 8)
                        .offset(x: x - 4, y: -2)
                }

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .shadow(radius: 2)
                    .offset(x: geo.size.width * progress - 6)
            }
            .frame(height: 12)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        progress = max(0, min(1, value.location.x / geo.size.width))
                    }
            )
        }
        .frame(height: 12)
    }
}

// MARK: - Models

struct TimelineMarker: Identifiable {
    let id = UUID()
    let time: TimeInterval
    let label: String
    let color: Color
}

enum PlaybackSpeed: Double, CaseIterable {
    case half = 0.5
    case normal = 1.0
    case double = 2.0
    case quad = 4.0
}

// MARK: - Recording Browser

struct RecordingBrowserView: View {
    @Bindable var viewModel: RecordingBrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.Recording.recordings)
                    .font(.headline)
                Spacer()
                Text("\(viewModel.recordings.count) \(L10n.Recording.recordings)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial)

            Divider()

            if viewModel.recordings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "record.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                    Text(L10n.Recording.none)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.recordings, id: \.path) { recording in
                    HStack {
                        Image(systemName: "play.circle")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(recording.lastPathComponent)
                                .font(.callout)
                            Text(recording.path)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.onSelect?(recording)
                    }
                }
            }
        }
    }
}

// MARK: - View Models

@Observable
final class PlaybackViewModel {
    var recordingName: String = ""
    var provider: String?
    var currentFrame: String = ""
    var progress: Double = 0
    var isPlaying: Bool = false
    var speed: PlaybackSpeed = .normal
    var markers: [TimelineMarker] = []
    var totalDuration: TimeInterval = 0

    private var events: [(TimeInterval, String, String)] = [] // (time, type, data)
    private var playbackTask: Task<Void, Never>?

    var currentTimeString: String { formatTime(progress * totalDuration) }
    var totalDurationString: String { formatTime(totalDuration) }

    func loadRecording(from url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        let lines = content.components(separatedBy: "\n")

        recordingName = url.lastPathComponent

        events = []
        for line in lines.dropFirst() where !line.isEmpty {
            if let data = line.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: data) as? [Any],
               arr.count >= 3,
               let time = arr[0] as? Double,
               let type = arr[1] as? String,
               let text = arr[2] as? String {
                events.append((time, type, text))
            }
        }

        totalDuration = events.last?.0 ?? 0
    }

    func togglePlay() {
        isPlaying.toggle()
        if isPlaying { startPlayback() }
        else { playbackTask?.cancel() }
    }

    func skipForward() { progress = min(1, progress + 10 / totalDuration) }
    func skipBackward() { progress = max(0, progress - 10 / totalDuration) }

    private func startPlayback() {
        playbackTask = Task { @MainActor in
            let startIdx = events.firstIndex { $0.0 / totalDuration >= progress } ?? 0
            for i in startIdx..<events.count {
                guard !Task.isCancelled else { break }
                let event = events[i]
                if event.1 == "o" {
                    currentFrame += event.2.replacingOccurrences(of: "\\n", with: "\n")
                                          .replacingOccurrences(of: "\\r", with: "\r")
                }
                progress = event.0 / totalDuration
                let delay = UInt64(1_000_000_000.0 / speed.rawValue * 0.01)
                try? await Task.sleep(nanoseconds: delay)
            }
            isPlaying = false
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

@Observable
final class RecordingBrowserViewModel {
    var recordings: [URL] = []
    var onSelect: ((URL) -> Void)?

    private let recordingEngine: RecordingEngine

    init(recordingEngine: RecordingEngine) {
        self.recordingEngine = recordingEngine
        refresh()
    }

    func refresh() {
        recordings = recordingEngine.listRecordings()
            .sorted { ($0.lastPathComponent) > ($1.lastPathComponent) }
    }
}
