// MARK: - Notification Manager

import Foundation

// MARK: - Protocol (ISP: narrow interface for notification dispatch)

public protocol NotificationManaging: AnyObject {
    func notifyNeedsInput(sessionId: String, sessionName: String)
    func notifyError(sessionId: String, sessionName: String, error: String)
    func notifyCostThreshold(sessionId: String, cost: Decimal, threshold: Decimal)
    func notifySessionCompleted(sessionId: String, sessionName: String)
}

// MARK: - No-Op Implementation (test-safe default, cross-platform)

/// A notification manager that discards all notifications.
/// Used as the default value in `FleetManager.init` so that unit tests
/// (which have no app bundle / UNUserNotificationCenter) do not crash.
/// Also used on non-macOS platforms where UserNotifications is unavailable.
public final class NoOpNotificationManager: NotificationManaging {
    public init() {}
    public func notifyNeedsInput(sessionId: String, sessionName: String) {}
    public func notifyError(sessionId: String, sessionName: String, error: String) {}
    public func notifyCostThreshold(sessionId: String, cost: Decimal, threshold: Decimal) {}
    public func notifySessionCompleted(sessionId: String, sessionName: String) {}
}

// MARK: - macOS Concrete Implementation

#if canImport(UserNotifications)
import UserNotifications

/// Dispatches `UNNotificationRequest` items for agent lifecycle events.
///
/// Design decisions:
/// - 30-second per-key cooldown prevents notification spam.
/// - A unique identifier (key + timestamp) avoids replacing pending
///   notifications from a previous cooldown window.
/// - `UNUserNotificationCenterDelegate` enables banner display while
///   the app is in the foreground.
/// - `requestPermission()` is called once at init; subsequent calls are
///   no-ops because the OS caches the user's decision.
public final class NotificationManager: NSObject, NotificationManaging {

    // MARK: - Constants

    private static let needsInputCategory  = "SESSION_NEEDS_INPUT"
    private static let errorCategory       = "AGENT_ERROR"
    private static let costAlertCategory   = "COST_ALERT"
    private static let completedCategory   = "SESSION_COMPLETE"

    // MARK: - State

    /// Maps a rate-limit key → the last time a notification was fired for it.
    private var lastNotificationTimes: [String: Date] = [:]
    private let rateLimitSeconds: TimeInterval = 30

    // MARK: - Initialization

    public override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        requestPermission()
    }

    // MARK: - Permission

    /// Requests UNAuthorization. Safe to call multiple times; the OS
    /// presents the system dialog only on the first call per app installation.
    public func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error {
                // Non-fatal — notifications are an enhancement, not a requirement.
                print("[NotificationManager] Authorization error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - NotificationManaging

    public func notifyNeedsInput(sessionId: String, sessionName: String) {
        let key = "input-\(sessionId)"
        guard shouldNotify(key: key) else { return }
        send(
            title: "Agent needs input",
            body: "\(sessionName) is waiting for your approval",
            identifier: uniqueIdentifier(base: key),
            category: Self.needsInputCategory,
            userInfo: ["sessionId": sessionId]
        )
    }

    public func notifyError(sessionId: String, sessionName: String, error: String) {
        let key = "error-\(sessionId)"
        guard shouldNotify(key: key) else { return }
        send(
            title: "Agent error",
            body: "\(sessionName): \(error)",
            identifier: uniqueIdentifier(base: key),
            category: Self.errorCategory,
            userInfo: ["sessionId": sessionId]
        )
    }

    public func notifyCostThreshold(sessionId: String, cost: Decimal, threshold: Decimal) {
        let key = "cost-\(sessionId)"
        guard shouldNotify(key: key) else { return }
        send(
            title: "Cost alert",
            body: "Session cost $\(cost) exceeded threshold $\(threshold)",
            identifier: uniqueIdentifier(base: key),
            category: Self.costAlertCategory,
            userInfo: ["sessionId": sessionId]
        )
    }

    public func notifySessionCompleted(sessionId: String, sessionName: String) {
        // Completion events are not rate-limited — they fire at most once per session.
        send(
            title: "Session completed",
            body: "\(sessionName) has finished",
            identifier: uniqueIdentifier(base: "complete-\(sessionId)"),
            category: Self.completedCategory,
            userInfo: ["sessionId": sessionId]
        )
    }

    // MARK: - Private helpers

    private func shouldNotify(key: String) -> Bool {
        if let last = lastNotificationTimes[key],
           Date().timeIntervalSince(last) < rateLimitSeconds {
            return false
        }
        lastNotificationTimes[key] = Date()
        return true
    }

    /// Appends a millisecond timestamp so that rapid back-to-back notifications
    /// (across cooldown windows) do not silently replace each other in the
    /// notification center.
    private func uniqueIdentifier(base: String) -> String {
        "\(base)-\(Int(Date().timeIntervalSince1970 * 1000))"
    }

    private func send(
        title: String,
        body: String,
        identifier: String,
        category: String,
        userInfo: [AnyHashable: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category
        content.sound = .default
        content.userInfo = userInfo

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationManager] Failed to schedule '\(identifier)': \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Show banners (alert + sound) even when the app is in the foreground.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Route taps back to the session that triggered the notification.
    /// Currently logs the sessionId; UI routing is wired by the App layer.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let sessionId = userInfo["sessionId"] as? String {
            NotificationCenter.default.post(
                name: .agentNotificationTapped,
                object: nil,
                userInfo: ["sessionId": sessionId]
            )
        }
        completionHandler()
    }
}

// MARK: - NSNotification.Name extension

public extension NSNotification.Name {
    /// Posted when the user taps a notification banner. `userInfo["sessionId"]`
    /// contains the `String` session identifier to focus in the UI.
    static let agentNotificationTapped = NSNotification.Name("AgentsBoardNotificationTapped")
}

#endif
