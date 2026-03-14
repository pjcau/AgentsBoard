// MARK: - Editor View (Step 9.3)
// Read-only code viewer with syntax highlighting and line numbers.

import SwiftUI
import AgentsBoardCore

struct EditorView: View {
    @Bindable var viewModel: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(viewModel.openFiles, id: \.path) { file in
                        EditorTab(
                            name: file.name,
                            isSelected: viewModel.activeFilePath == file.path,
                            isModified: file.isModified
                        ) {
                            viewModel.activeFilePath = file.path
                        } onClose: {
                            viewModel.closeFile(file.path)
                        }
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Editor content
            if let content = viewModel.activeContent {
                ScrollView([.horizontal, .vertical]) {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        ForEach(Array(content.lines.enumerated()), id: \.offset) { index, line in
                            HStack(spacing: 0) {
                                // Line number
                                Text("\(index + 1)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                                    .frame(minWidth: 36, alignment: .trailing)
                                    .padding(.trailing, 8)

                                // Line content
                                Text(attributedLine(line))
                                    .font(.system(.callout, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 1)
                            .background(highlightBackground(index + 1))
                        }
                    }
                    .padding(8)
                }
            } else {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                    Text(L10n.Editor.selectFile)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func attributedLine(_ line: EditorLine) -> AttributedString {
        var result = AttributedString(line.text)
        for token in line.tokens {
            let start = result.index(result.startIndex, offsetByCharacters: token.range.lowerBound)
            let end = result.index(result.startIndex, offsetByCharacters: min(token.range.upperBound, line.text.count))
            if start < end {
                result[start..<end].foregroundColor = tokenColor(token.type)
            }
        }
        return result
    }

    private func tokenColor(_ type: TokenType) -> Color {
        switch type {
        case .keyword: return .pink
        case .string: return .green
        case .comment: return .gray
        case .number: return .orange
        case .type: return .cyan
        case .function: return .yellow
        case .property: return .purple
        case .plain: return .primary
        }
    }

    private func highlightBackground(_ lineNumber: Int) -> Color {
        viewModel.highlightedLines.contains(lineNumber) ? Color.yellow.opacity(0.1) : Color.clear
    }
}

// MARK: - Editor Tab

struct EditorTab: View {
    let name: String
    let isSelected: Bool
    let isModified: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            if isModified {
                Circle()
                    .fill(.orange)
                    .frame(width: 6, height: 6)
            }
            Text(name)
                .font(.caption)
                .lineLimit(1)
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color(nsColor: .windowBackgroundColor) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}

// MARK: - Models

struct EditorFile {
    let path: String
    let name: String
    let content: EditorContent
    var isModified: Bool = false
}

struct EditorContent {
    let lines: [EditorLine]
}

struct EditorLine {
    let text: String
    let tokens: [SyntaxToken]
}

struct SyntaxToken {
    let range: Range<Int>
    let type: TokenType
}

enum TokenType {
    case keyword, string, comment, number, type, function, property, plain
}

// MARK: - Basic Syntax Highlighter

struct SyntaxHighlighter {
    func highlight(_ source: String, language: String) -> EditorContent {
        let lines = source.components(separatedBy: "\n")
        return EditorContent(lines: lines.map { highlightLine($0, language: language) })
    }

    private func highlightLine(_ line: String, language: String) -> EditorLine {
        var tokens: [SyntaxToken] = []
        let keywords: Set<String>

        switch language {
        case "swift":
            keywords = ["func", "var", "let", "class", "struct", "enum", "protocol",
                       "import", "return", "if", "else", "guard", "switch", "case",
                       "for", "while", "in", "self", "true", "false", "nil",
                       "private", "public", "internal", "final", "static", "override",
                       "init", "deinit", "throws", "async", "await", "some", "any"]
        default:
            keywords = []
        }

        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("//") || trimmed.hasPrefix("#") {
            tokens.append(SyntaxToken(range: 0..<line.count, type: .comment))
        } else {
            let words = line.split(separator: " ", omittingEmptySubsequences: false)
            var offset = 0
            for word in words {
                let w = String(word)
                if keywords.contains(w) {
                    tokens.append(SyntaxToken(range: offset..<(offset + w.count), type: .keyword))
                } else if w.hasPrefix("\"") || w.hasPrefix("'") {
                    tokens.append(SyntaxToken(range: offset..<(offset + w.count), type: .string))
                } else if w.first?.isNumber == true {
                    tokens.append(SyntaxToken(range: offset..<(offset + w.count), type: .number))
                }
                offset += w.count + 1
            }
        }

        return EditorLine(text: line, tokens: tokens)
    }
}

// MARK: - View Model

@Observable
final class EditorViewModel {
    var openFiles: [EditorFile] = []
    var activeFilePath: String?
    var highlightedLines: Set<Int> = []

    private let highlighter = SyntaxHighlighter()

    var activeContent: EditorContent? {
        openFiles.first { $0.path == activeFilePath }?.content
    }

    func openFile(at path: String) {
        guard !openFiles.contains(where: { $0.path == path }) else {
            activeFilePath = path
            return
        }

        let name = (path as NSString).lastPathComponent
        let ext = (name as NSString).pathExtension
        let language = languageFor(ext)

        guard let source = try? String(contentsOfFile: path, encoding: .utf8) else { return }

        let content = highlighter.highlight(source, language: language)
        let file = EditorFile(path: path, name: name, content: content)
        openFiles.append(file)
        activeFilePath = path
    }

    func closeFile(_ path: String) {
        openFiles.removeAll { $0.path == path }
        if activeFilePath == path {
            activeFilePath = openFiles.last?.path
        }
    }

    private func languageFor(_ ext: String) -> String {
        switch ext.lowercased() {
        case "swift": return "swift"
        case "py": return "python"
        case "js", "jsx": return "javascript"
        case "ts", "tsx": return "typescript"
        case "rs": return "rust"
        case "go": return "go"
        default: return "text"
        }
    }
}
