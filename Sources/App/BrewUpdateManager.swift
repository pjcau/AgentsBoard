// MARK: - Brew Update Manager

import Foundation
import AppKit

/// Manages app updates via Homebrew cask.
///
/// SRP: Only responsible for checking/applying updates via `brew`.
/// DIP: Could conform to an `AppUpdating` protocol if needed for testing.
@Observable
final class BrewUpdateManager {

    // MARK: - State

    enum UpdateState: Equatable {
        case idle
        case checking
        case available(latest: String)
        case upToDate
        case updating
        case restartRequired
        case error(String)
    }

    private(set) var state: UpdateState = .idle

    /// Current app version from Info.plist
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    // MARK: - Check for Updates

    /// Queries `brew info --cask` to find the latest available version.
    func checkForUpdates() async {
        state = .checking

        do {
            let latest = try await fetchLatestBrewVersion()
            if latest != currentVersion && latest > currentVersion {
                state = .available(latest: latest)
            } else {
                state = .upToDate
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Apply Update

    /// Runs `brew upgrade --cask agentsboard` then relaunches the app.
    func applyUpdate() async {
        state = .updating

        do {
            try await runBrewUpgrade()
            state = .restartRequired
            // Brief pause so the UI can show "Restarting..."
            try? await Task.sleep(for: .milliseconds(500))
            relaunchApp()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Private

    private func fetchLatestBrewVersion() async throws -> String {
        let output = try await shell("/opt/homebrew/bin/brew", "info", "--cask", "pjcau/agentsboard/agentsboard")
        // First line: "agentsboard: 0.9.2"
        guard let firstLine = output.split(separator: "\n").first else {
            throw UpdateError.parseFailure
        }
        // Extract version after last space or colon
        let parts = firstLine.split(separator: " ")
        guard let version = parts.last else {
            throw UpdateError.parseFailure
        }
        return String(version)
    }

    private func runBrewUpgrade() async throws {
        _ = try await shell("/opt/homebrew/bin/brew", "upgrade", "--cask", "agentsboard")
    }

    private func shell(_ args: String...) async throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: args[0])
        process.arguments = Array(args.dropFirst())
        process.standardOutput = pipe
        process.standardError = pipe
        // Inherit PATH so brew can find its dependencies
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = env

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { proc in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: UpdateError.brewFailed(output.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Callback set by CompositionRoot to save sessions before quit.
    var onSaveBeforeQuit: (() -> Void)?

    private func relaunchApp() {
        guard let appURL = Bundle.main.bundleURL as URL? else { return }

        // Save current sessions so they can be restored after relaunch
        onSaveBeforeQuit?()

        // Launch a background process that waits for the app to fully exit,
        // then reopens it. Uses a retry loop in case brew is still writing files.
        let script = """
        while kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do
            sleep 0.5
        done
        sleep 1
        open "\(appURL.path)"
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        try? process.run()

        // Force quit without confirmation dialog (terminate(nil) shows "Do you want to quit?")
        DispatchQueue.main.async {
            NSApplication.shared.reply(toApplicationShouldTerminate: true)
            exit(0)
        }
    }

    // MARK: - Errors

    enum UpdateError: LocalizedError {
        case parseFailure
        case brewFailed(String)

        var errorDescription: String? {
            switch self {
            case .parseFailure:
                return "Could not parse brew version output"
            case .brewFailed(let msg):
                return "brew upgrade failed: \(msg)"
            }
        }
    }
}
