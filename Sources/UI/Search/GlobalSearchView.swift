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
    private weak var fleetManager: (any FleetManaging)?

    init(activityLogger: ActivityLogger, fleetManager: (any FleetManaging)? = nil) {
        self.activityLogger = activityLogger
        self.fleetManager = fleetManager
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

        // Search session output
        if scope == .all || scope == .output {
            let sessions = fleetManager?.sessions ?? []
            for session in sessions {
                let output = session.outputText
                guard !output.isEmpty, output.lowercased().contains(queryLower) else { continue }

                // Extract context snippet around the match
                let snippet = extractSnippet(from: output, query: queryLower)
                found.append(SearchResult(
                    type: .output,
                    title: session.sessionName,
                    contextSnippet: snippet,
                    source: String(session.sessionId.prefix(8)),
                    sessionId: session.sessionId,
                    filePath: nil,
                    lineNumber: nil,
                    relevanceScore: 0.9
                ))
            }
        }

        // Search files in session workspaces
        if scope == .all || scope == .files {
            let sessions = fleetManager?.sessions ?? []
            var searchedPaths = Set<String>()

            for session in sessions {
                guard let projectPath = session.projectPath,
                      !projectPath.isEmpty,
                      !searchedPaths.contains(projectPath) else { continue }
                searchedPaths.insert(projectPath)

                let fileResults = searchFiles(in: projectPath, query: queryLower, sessionId: session.sessionId)
                found.append(contentsOf: fileResults.prefix(20))
            }
        }

        results = found.sorted { $0.relevanceScore > $1.relevanceScore }
        searchDuration = Date().timeIntervalSince(start)
        isSearching = false
    }

    private func extractSnippet(from text: String, query: String) -> String {
        let lower = text.lowercased()
        guard let range = lower.range(of: query) else { return String(text.prefix(100)) }

        let matchStart = text.distance(from: text.startIndex, to: range.lowerBound)
        let snippetStart = max(0, matchStart - 40)
        let startIndex = text.index(text.startIndex, offsetBy: snippetStart)
        let endIndex = text.index(startIndex, offsetBy: min(120, text.distance(from: startIndex, to: text.endIndex)))

        var snippet = String(text[startIndex..<endIndex])
        if snippetStart > 0 { snippet = "..." + snippet }
        if endIndex < text.endIndex { snippet += "..." }
        return snippet.replacingOccurrences(of: "\n", with: " ")
    }

    private func searchFiles(in directory: String, query: String, sessionId: String) -> [SearchResult] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: directory) else { return [] }

        var results: [SearchResult] = []
        let textExtensions: Set<String> = ["swift", "py", "js", "ts", "tsx", "jsx", "json", "yml", "yaml", "md", "txt", "rs", "go", "rb", "java", "kt", "c", "cpp", "h", "css", "html"]

        while let relativePath = enumerator.nextObject() as? String {
            // Skip hidden dirs and common noise
            if relativePath.hasPrefix(".") || relativePath.contains("node_modules") || relativePath.contains(".build") {
                continue
            }

            let fullPath = directory + "/" + relativePath
            let ext = (relativePath as NSString).pathExtension.lowercased()
            guard textExtensions.contains(ext) else { continue }

            // Check filename match
            let fileName = (relativePath as NSString).lastPathComponent.lowercased()
            if fileName.contains(query) {
                results.append(SearchResult(
                    type: .file,
                    title: (relativePath as NSString).lastPathComponent,
                    contextSnippet: relativePath,
                    source: (directory as NSString).lastPathComponent,
                    sessionId: sessionId,
                    filePath: fullPath,
                    lineNumber: nil,
                    relevanceScore: 0.85
                ))
            }

            // Search file contents (only small files)
            guard results.count < 50 else { break }
            guard let attrs = try? fm.attributesOfItem(atPath: fullPath),
                  let size = attrs[.size] as? UInt64, size < 500_000,
                  let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else { continue }

            let lines = content.components(separatedBy: "\n")
            for (lineIndex, line) in lines.enumerated() {
                if line.lowercased().contains(query) {
                    results.append(SearchResult(
                        type: .file,
                        title: (relativePath as NSString).lastPathComponent,
                        contextSnippet: line.trimmingCharacters(in: .whitespaces),
                        source: (directory as NSString).lastPathComponent,
                        sessionId: sessionId,
                        filePath: fullPath,
                        lineNumber: lineIndex + 1,
                        relevanceScore: 0.8
                    ))
                    break // One match per file for content search
                }
            }
        }

        return results
    }
}
