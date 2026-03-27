// MARK: - Session Persistence
// Saves and restores active sessions across app restarts.
// SRP: Only responsible for encoding/decoding session state to UserDefaults.

import Foundation
import AgentsBoardCore

/// A lightweight snapshot of a session for persistence across restarts.
struct PersistedSession: Codable {
    let name: String
    let command: String
    let workDir: String?
    let provider: String?
}

/// Saves and restores session state using UserDefaults.
///
/// SRP: Only handles session serialization — no UI, no fleet management.
/// DIP: Depends on FleetManaging protocol, not concrete FleetManager.
struct SessionPersistence {

    private static let key = "agentsboard.persistedSessions"

    /// Saves current fleet sessions to UserDefaults.
    static func save(sessions: [any AgentSessionRepresentable]) {
        let snapshots = sessions.compactMap { session -> PersistedSession? in
            guard let command = session.launchCommand, !command.isEmpty else { return nil }
            return PersistedSession(
                name: session.sessionName,
                command: command,
                workDir: session.projectPath,
                provider: session.agentInfo?.provider.rawValue
            )
        }

        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Loads persisted sessions from UserDefaults.
    static func load() -> [PersistedSession] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let sessions = try? JSONDecoder().decode([PersistedSession].self, from: data) else {
            return []
        }
        return sessions
    }

    /// Clears persisted sessions (called after successful restore).
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
