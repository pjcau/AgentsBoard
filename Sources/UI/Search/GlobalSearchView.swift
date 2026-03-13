// MARK: - Global Search View (Step 11.2)
// Cross-session search across agent outputs, files, and activity.

import SwiftUI
import AgentsBoardCore

struct GlobalSearchView: View {
    @Bindable var viewModel: GlobalSearchViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search across sessions, files, activity...", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onSubmit { viewModel.search() }

                Picker("Scope", selection: $viewModel.scope) {
                    Text("All").tag(SearchScope.all)
                    Text("Output").tag(SearchScope.output)
                    Text("Files").tag(SearchScope.files)
                    Text("Activity").tag(SearchScope.activity)
                }
                .frame(maxWidth: 150)

                if viewModel.isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)

            Divider()

            // Results
            if viewModel.results.isEmpty && !viewModel.query.isEmpty && !viewModel.isSearching {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                    Text("No results found")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.results) { result in
                            SearchResultRow(result: result)
                                .onTapGesture {
                                    viewModel.onResultTap?(result)
                                }
                        }
                    }
                    .padding(12)
                }
            }

            // Status bar
            if !viewModel.results.isEmpty {
                HStack {
                    Text("\(viewModel.results.count) results")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let elapsed = viewModel.searchDuration {
                        Text(String(format: "%.1fms", elapsed * 1000))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: resultIcon)
                .font(.caption)
                .foregroundStyle(resultColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.callout)
                    .lineLimit(1)

                Text(result.contextSnippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(result.source)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if let line = result.lineNumber {
                    Text("L\(line)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var resultIcon: String {
        switch result.type {
        case .output: return "terminal"
        case .file: return "doc.text"
        case .activity: return "clock"
        }
    }

    private var resultColor: Color {
        switch result.type {
        case .output: return .blue
        case .file: return .orange
        case .activity: return .green
        }
    }
}

// MARK: - Models

enum SearchScope: String, Sendable {
    case all, output, files, activity
}

enum SearchResultType: Sendable {
    case output, file, activity
}

struct SearchResult: Identifiable {
    let id = UUID()
    let type: SearchResultType
    let title: String
    let contextSnippet: String
    let source: String
    let sessionId: String?
    let filePath: String?
    let lineNumber: Int?
    let relevanceScore: Double
}

// MARK: - View Model

@Observable
final class GlobalSearchViewModel {
    var query: String = ""
    var scope: SearchScope = .all
    var results: [SearchResult] = []
    var isSearching: Bool = false
    var searchDuration: TimeInterval?
    var onResultTap: ((SearchResult) -> Void)?

    private let activityLogger: ActivityLogger

    init(activityLogger: ActivityLogger) {
        self.activityLogger = activityLogger
    }

    func search() {
        guard !query.isEmpty else {
            results = []
            return
        }

        isSearching = true
        let start = Date()
        let queryLower = query.lowercased()

        var found: [SearchResult] = []

        // Search activity events
        if scope == .all || scope == .activity {
            let events = activityLogger.allEvents.filter {
                $0.details.lowercased().contains(queryLower)
            }
            for event in events.prefix(50) {
                found.append(SearchResult(
                    type: .activity,
                    title: event.details,
                    contextSnippet: "\(event.eventType.rawValue) at \(event.timestamp)",
                    source: String(event.sessionId.prefix(8)),
                    sessionId: event.sessionId,
                    filePath: nil,
                    lineNumber: nil,
                    relevanceScore: 1.0
                ))
            }
        }

        results = found.sorted { $0.relevanceScore > $1.relevanceScore }
        searchDuration = Date().timeIntervalSince(start)
        isSearching = false
    }
}
