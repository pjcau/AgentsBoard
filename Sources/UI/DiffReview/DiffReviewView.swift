// MARK: - Diff Review View (Step 9.1)
// Side-by-side and unified diff viewer for agent file changes.

import SwiftUI
import AgentsBoardCore

enum DiffViewMode: String, CaseIterable {
    case unified
    case sideBySide
}

struct DiffReviewView: View {
    @Bindable var viewModel: DiffReviewViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(viewModel.fileName)
                    .font(.headline)

                Spacer()

                HStack(spacing: 4) {
                    Text("+\(viewModel.additions)")
                        .foregroundStyle(.green)
                    Text("-\(viewModel.deletions)")
                        .foregroundStyle(.red)
                }
                .font(.callout)

                Picker("View", selection: $viewModel.viewMode) {
                    Text("Unified").tag(DiffViewMode.unified)
                    Text("Side by Side").tag(DiffViewMode.sideBySide)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)

                Button {
                    viewModel.approve()
                } label: {
                    Label("Approve", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    viewModel.reject()
                } label: {
                    Label("Reject", systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(12)
            .background(.ultraThinMaterial)

            Divider()

            // Diff content
            switch viewModel.viewMode {
            case .unified:
                UnifiedDiffView(hunks: viewModel.hunks)
            case .sideBySide:
                SideBySideDiffView(hunks: viewModel.hunks)
            }
        }
    }
}

// MARK: - Diff Models

struct DiffHunk: Identifiable {
    let id = UUID()
    let header: String
    let lines: [DiffLine]
}

struct DiffLine: Identifiable {
    let id = UUID()
    let type: DiffLineType
    let oldLineNumber: Int?
    let newLineNumber: Int?
    let content: String
}

enum DiffLineType {
    case context
    case addition
    case deletion
    case header
}

// MARK: - Unified Diff View

struct UnifiedDiffView: View {
    let hunks: [DiffHunk]

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0) {
                ForEach(hunks) { hunk in
                    // Hunk header
                    Text(hunk.header)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.05))

                    ForEach(hunk.lines) { line in
                        HStack(spacing: 0) {
                            // Line numbers
                            Group {
                                Text(line.oldLineNumber.map(String.init) ?? "")
                                    .frame(minWidth: 36, alignment: .trailing)
                                Text(line.newLineNumber.map(String.init) ?? "")
                                    .frame(minWidth: 36, alignment: .trailing)
                            }
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 4)

                            // Prefix
                            Text(linePrefix(line.type))
                                .font(.system(.callout, design: .monospaced))
                                .foregroundStyle(lineColor(line.type))
                                .frame(width: 16)

                            // Content
                            Text(line.content)
                                .font(.system(.callout, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 1)
                        .background(lineBackground(line.type))
                    }
                }
            }
        }
    }

    private func linePrefix(_ type: DiffLineType) -> String {
        switch type {
        case .addition: return "+"
        case .deletion: return "-"
        case .context: return " "
        case .header: return "@"
        }
    }

    private func lineColor(_ type: DiffLineType) -> Color {
        switch type {
        case .addition: return .green
        case .deletion: return .red
        default: return .secondary
        }
    }

    private func lineBackground(_ type: DiffLineType) -> Color {
        switch type {
        case .addition: return .green.opacity(0.08)
        case .deletion: return .red.opacity(0.08)
        default: return .clear
        }
    }
}

// MARK: - Side by Side Diff View

struct SideBySideDiffView: View {
    let hunks: [DiffHunk]

    var body: some View {
        HStack(spacing: 0) {
            // Old file
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(hunks) { hunk in
                        ForEach(hunk.lines) { line in
                            if line.type != .addition {
                                SideDiffLine(
                                    lineNumber: line.oldLineNumber,
                                    content: line.content,
                                    type: line.type == .deletion ? .deletion : .context
                                )
                            }
                        }
                    }
                }
            }

            Divider()

            // New file
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(hunks) { hunk in
                        ForEach(hunk.lines) { line in
                            if line.type != .deletion {
                                SideDiffLine(
                                    lineNumber: line.newLineNumber,
                                    content: line.content,
                                    type: line.type == .addition ? .addition : .context
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SideDiffLine: View {
    let lineNumber: Int?
    let content: String
    let type: DiffLineType

    var body: some View {
        HStack(spacing: 0) {
            Text(lineNumber.map(String.init) ?? "")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(minWidth: 36, alignment: .trailing)
                .padding(.trailing, 8)

            Text(content)
                .font(.system(.callout, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 1)
        .padding(.horizontal, 4)
        .background(type == .addition ? Color.green.opacity(0.08) :
                    type == .deletion ? Color.red.opacity(0.08) : Color.clear)
    }
}

// MARK: - Diff Parser

struct DiffParser {
    func parse(unifiedDiff: String) -> [DiffHunk] {
        let lines = unifiedDiff.components(separatedBy: "\n")
        var hunks: [DiffHunk] = []
        var currentLines: [DiffLine] = []
        var currentHeader = ""
        var oldLine = 0
        var newLine = 0

        for line in lines {
            if line.hasPrefix("@@") {
                if !currentLines.isEmpty {
                    hunks.append(DiffHunk(header: currentHeader, lines: currentLines))
                    currentLines = []
                }
                currentHeader = line
                // Parse @@ -a,b +c,d @@
                let parts = line.components(separatedBy: " ")
                if parts.count >= 3 {
                    let oldPart = parts[1].dropFirst() // Remove -
                    let newPart = parts[2].dropFirst() // Remove +
                    oldLine = Int(oldPart.components(separatedBy: ",").first ?? "0") ?? 0
                    newLine = Int(newPart.components(separatedBy: ",").first ?? "0") ?? 0
                }
            } else if line.hasPrefix("+") && !line.hasPrefix("+++") {
                currentLines.append(DiffLine(
                    type: .addition, oldLineNumber: nil,
                    newLineNumber: newLine, content: String(line.dropFirst())
                ))
                newLine += 1
            } else if line.hasPrefix("-") && !line.hasPrefix("---") {
                currentLines.append(DiffLine(
                    type: .deletion, oldLineNumber: oldLine,
                    newLineNumber: nil, content: String(line.dropFirst())
                ))
                oldLine += 1
            } else if line.hasPrefix(" ") {
                currentLines.append(DiffLine(
                    type: .context, oldLineNumber: oldLine,
                    newLineNumber: newLine, content: String(line.dropFirst())
                ))
                oldLine += 1
                newLine += 1
            }
        }

        if !currentLines.isEmpty {
            hunks.append(DiffHunk(header: currentHeader, lines: currentLines))
        }

        return hunks
    }
}

// MARK: - View Model

@Observable
final class DiffReviewViewModel {
    var viewMode: DiffViewMode = .unified
    var fileName: String = ""
    var hunks: [DiffHunk] = []
    var onApprove: (() -> Void)?
    var onReject: (() -> Void)?

    var additions: Int { hunks.flatMap(\.lines).filter { $0.type == .addition }.count }
    var deletions: Int { hunks.flatMap(\.lines).filter { $0.type == .deletion }.count }

    private let parser = DiffParser()

    func loadDiff(fileName: String, content: String) {
        self.fileName = fileName
        self.hunks = parser.parse(unifiedDiff: content)
    }

    func approve() { onApprove?() }
    func reject() { onReject?() }
}
