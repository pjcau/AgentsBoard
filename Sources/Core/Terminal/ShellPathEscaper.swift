// MARK: - Shell Path Escaper
// Escapes file paths for safe insertion into terminal input.
// Used by drag-and-drop on both macOS (SwiftUI) and Linux (Qt via FFI).

import Foundation

/// Escapes file paths for safe pasting into a shell session.
///
/// Follows SRP: this type does one thing — escape paths for shell input.
/// Used by both macOS (SwiftUI drag-and-drop) and Linux (Qt DropArea via FFI).
public struct ShellPathEscaper {

    /// Escapes a single file path for shell input.
    /// Wraps in single quotes and escapes any embedded single quotes.
    public static func escape(_ path: String) -> String {
        // Replace ' with '\'' (end quote, escaped quote, restart quote)
        let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    /// Formats multiple file paths as a space-separated shell-safe string.
    public static func formatPaths(_ paths: [String]) -> String {
        paths.map { escape($0) }.joined(separator: " ")
    }

    /// Formats a file path for a specific agent provider.
    /// Claude Code uses `@path` for images, other providers use raw paths.
    public static func formatForProvider(
        _ path: String,
        isImage: Bool,
        providerName: String
    ) -> String {
        if providerName == "claude" && isImage {
            return "@" + escape(path)
        }
        return escape(path)
    }
}
