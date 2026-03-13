// MARK: - File Explorer View (Step 9.2)
// Tree-based file browser showing agent workspace files.

import SwiftUI
import AgentsBoardCore

struct FileNode: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    var children: [FileNode]?
    var isModified: Bool = false
    var modifiedBy: String? = nil
}

struct FileExplorerView: View {
    @Bindable var viewModel: FileExplorerViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(viewModel.rootName)
                    .font(.callout)
                    .fontWeight(.medium)
                Spacer()
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(8)
            .background(.ultraThinMaterial)

            Divider()

            // Tree
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.rootNodes) { node in
                        FileTreeRow(node: node, depth: 0, viewModel: viewModel)
                    }
                }
                .padding(4)
            }
        }
    }
}

// MARK: - File Tree Row

struct FileTreeRow: View {
    let node: FileNode
    let depth: Int
    @Bindable var viewModel: FileExplorerViewModel

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                // Indentation
                Spacer()
                    .frame(width: CGFloat(depth) * 16)

                // Disclosure indicator
                if node.isDirectory {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(width: 12)
                } else {
                    Spacer().frame(width: 12)
                }

                // Icon
                Image(systemName: iconFor(node))
                    .font(.caption)
                    .foregroundStyle(iconColor(node))
                    .frame(width: 16)

                // Name
                Text(node.name)
                    .font(.callout)
                    .lineLimit(1)

                Spacer()

                // Modified indicator
                if node.isModified {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 3)
            .padding(.horizontal, 4)
            .background(viewModel.selectedPath == node.path ? Color.accentColor.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .contentShape(Rectangle())
            .onTapGesture {
                if node.isDirectory {
                    isExpanded.toggle()
                } else {
                    viewModel.selectFile(node.path)
                }
            }

            // Children
            if isExpanded, let children = node.children {
                ForEach(children) { child in
                    FileTreeRow(node: child, depth: depth + 1, viewModel: viewModel)
                }
            }
        }
    }

    private func iconFor(_ node: FileNode) -> String {
        if node.isDirectory { return "folder.fill" }
        let ext = (node.name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "py": return "text.page"
        case "js", "ts", "jsx", "tsx": return "curlybraces"
        case "json": return "doc.text"
        case "yml", "yaml": return "gearshape"
        case "md": return "doc.richtext"
        case "metal": return "cube"
        default: return "doc"
        }
    }

    private func iconColor(_ node: FileNode) -> Color {
        if node.isModified { return .orange }
        if node.isDirectory { return .blue }
        return .secondary
    }
}

// MARK: - View Model

@Observable
final class FileExplorerViewModel {
    var rootNodes: [FileNode] = []
    var selectedPath: String?
    var rootName: String = "Workspace"

    var onFileSelected: ((String) -> Void)?

    func selectFile(_ path: String) {
        selectedPath = path
        onFileSelected?(path)
    }

    func refresh() {
        // Re-scan workspace directory
    }

    func loadDirectory(at path: String) {
        rootName = (path as NSString).lastPathComponent
        rootNodes = scanDirectory(path)
    }

    private func scanDirectory(_ path: String) -> [FileNode] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return [] }

        return contents
            .filter { !$0.hasPrefix(".") }
            .sorted { lhs, rhs in
                let lhsDir = isDir(path + "/" + lhs)
                let rhsDir = isDir(path + "/" + rhs)
                if lhsDir != rhsDir { return lhsDir }
                return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
            }
            .map { name in
                let fullPath = path + "/" + name
                let dir = isDir(fullPath)
                return FileNode(
                    name: name,
                    path: fullPath,
                    isDirectory: dir,
                    children: dir ? scanDirectory(fullPath) : nil
                )
            }
    }

    private func isDir(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
}
