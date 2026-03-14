// MARK: - Worktree Manager View
// List, create, and delete git worktrees from the UI.

import SwiftUI
import AppKit

struct WorktreeInfo: Identifiable {
    let id = UUID()
    let path: String
    let branch: String
    let isMain: Bool
    let shortPath: String
}

struct WorktreeManagerView: View {
    let projectPath: String
    let onOpenSession: ((String, String) -> Void)? // (worktreePath, branch)

    @State private var worktrees: [WorktreeInfo] = []
    @State private var loading = true
    @State private var newBranch = ""
    @State private var showingCreate = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(.cyan)
                Text("Worktrees")
                    .font(.headline)
                Spacer()
                Button {
                    showingCreate.toggle()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Create worktree")

                Button {
                    loadWorktrees()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh")
            }
            .padding(12)

            Divider()

            if loading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if worktrees.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("No worktrees")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(shortenPath(projectPath))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(worktrees) { wt in
                            WorktreeRow(
                                worktree: wt,
                                onOpen: {
                                    onOpenSession?(wt.path, wt.branch)
                                },
                                onDelete: {
                                    deleteWorktree(wt)
                                },
                                onReveal: {
                                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: wt.path)
                                }
                            )
                        }
                    }
                    .padding(8)
                }
            }

            // Error display
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Spacer()
                    Button("Dismiss") { errorMessage = nil }
                        .buttonStyle(.borderless)
                        .font(.caption)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
            }

            // Create worktree
            if showingCreate {
                Divider()
                HStack {
                    TextField("Branch name", text: $newBranch)
                        .textFieldStyle(.roundedBorder)
                    Button("Create") {
                        createWorktree()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newBranch.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(10)
            }
        }
        .onAppear { loadWorktrees() }
    }

    // MARK: - Git Operations

    private func loadWorktrees() {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = runGit(["worktree", "list", "--porcelain"], at: projectPath)
            let infos = parseWorktreeList(result)
            DispatchQueue.main.async {
                worktrees = infos
                loading = false
            }
        }
    }

    private func createWorktree() {
        let branch = newBranch.trimmingCharacters(in: .whitespaces)
        guard !branch.isEmpty else { return }
        let wtPath = projectPath + "-worktrees/" + branch

        DispatchQueue.global(qos: .userInitiated).async {
            // Create directory if needed
            let parentDir = (wtPath as NSString).deletingLastPathComponent
            try? FileManager.default.createDirectory(atPath: parentDir, withIntermediateDirectories: true)

            let (_, exitCode) = runGitWithStatus(["worktree", "add", "-b", branch, wtPath], at: projectPath)
            DispatchQueue.main.async {
                if exitCode == 0 {
                    newBranch = ""
                    showingCreate = false
                    loadWorktrees()
                } else {
                    errorMessage = "Failed to create worktree '\(branch)'"
                }
            }
        }
    }

    private func deleteWorktree(_ wt: WorktreeInfo) {
        guard !wt.isMain else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let (_, exitCode) = runGitWithStatus(["worktree", "remove", wt.path, "--force"], at: projectPath)
            DispatchQueue.main.async {
                if exitCode == 0 {
                    // Also delete the branch
                    _ = runGit(["branch", "-D", wt.branch], at: projectPath)
                    loadWorktrees()
                } else {
                    errorMessage = "Failed to remove worktree"
                }
            }
        }
    }

    // MARK: - Helpers

    private func parseWorktreeList(_ output: String) -> [WorktreeInfo] {
        var results: [WorktreeInfo] = []
        var currentPath: String?
        var currentBranch: String?
        var isBare = false

        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("worktree ") {
                // Save previous entry
                if let path = currentPath {
                    let branch = currentBranch ?? "detached"
                    let isMain = results.isEmpty && !isBare
                    results.append(WorktreeInfo(
                        path: path,
                        branch: branch,
                        isMain: isMain,
                        shortPath: shortenPath(path)
                    ))
                }
                currentPath = String(line.dropFirst("worktree ".count))
                currentBranch = nil
                isBare = false
            } else if line.hasPrefix("branch ") {
                let ref = String(line.dropFirst("branch ".count))
                currentBranch = ref.replacingOccurrences(of: "refs/heads/", with: "")
            } else if line == "bare" {
                isBare = true
            }
        }
        // Save last entry
        if let path = currentPath {
            let branch = currentBranch ?? "detached"
            let isMain = results.isEmpty
            results.append(WorktreeInfo(
                path: path,
                branch: branch,
                isMain: isMain,
                shortPath: shortenPath(path)
            ))
        }
        return results
    }

    private func runGit(_ args: [String], at path: String) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = URL(fileURLWithPath: path)
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    private func runGitWithStatus(_ args: [String], at path: String) -> (String, Int32) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = URL(fileURLWithPath: path)
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return (String(data: data, encoding: .utf8) ?? "", process.terminationStatus)
        } catch {
            return ("", -1)
        }
    }

    private func shortenPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

// MARK: - Worktree Row

private struct WorktreeRow: View {
    let worktree: WorktreeInfo
    let onOpen: () -> Void
    let onDelete: () -> Void
    let onReveal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: worktree.isMain ? "star.fill" : "arrow.triangle.branch")
                    .font(.caption)
                    .foregroundStyle(worktree.isMain ? .yellow : .cyan)

                Text(worktree.branch)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                if worktree.isMain {
                    Text("main")
                        .font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.15))
                        .foregroundStyle(.yellow)
                        .clipShape(Capsule())
                }
            }

            Text(worktree.shortPath)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.head)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contextMenu {
            Button("Open Session Here") { onOpen() }
            Button("Reveal in Finder") { onReveal() }
            if !worktree.isMain {
                Divider()
                Button("Delete Worktree", role: .destructive) { onDelete() }
            }
        }
    }
}
