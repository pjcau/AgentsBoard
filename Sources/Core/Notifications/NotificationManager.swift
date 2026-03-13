// MARK: - Notification Manager (Step 6.3)

import Foundation
import UserNotifications

public protocol NotificationManaging: AnyObject {
    func notifyNeedsInput(sessionId: String, sessionName: String)
    func notifyError(sessionId: String, sessionName: String, error: String)
    func notifyCostThreshold(sessionId: String, cost: Decimal, threshold: Decimal)
    func notifySessionCompleted(sessionId: String, sessionName: String)
}

public final class NotificationManager: NotificationManaging {

    private var lastNotificationTimes: [String: Date] = [:]
    private let rateLimitSeconds: TimeInterval = 30

    public init() {
        requestPermission()
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    public func notifyNeedsInput(sessionId: String, sessionName: String) {
        guard shouldNotify(key: "input-\(sessionId)") else { return }
        send(
            title: "Agent needs input",
            body: "\(sessionName) is waiting for your approval",
            identifier: "input-\(sessionId)",
            category: "AGENT_INPUT"
        )
    }

    public func notifyError(sessionId: String, sessionName: String, error: String) {
        guard shouldNotify(key: "error-\(sessionId)") else { return }
        send(
            title: "Agent error",
            body: "\(sessionName): \(error)",
            identifier: "error-\(sessionId)",
            category: "AGENT_ERROR"
        )
    }

    public func notifyCostThreshold(sessionId: String, cost: Decimal, threshold: Decimal) {
        guard shouldNotify(key: "cost-\(sessionId)") else { return }
        send(
            title: "Cost alert",
            body: "Session cost $\(cost) exceeded threshold $\(threshold)",
            identifier: "cost-\(sessionId)",
            category: "COST_ALERT"
        )
    }

    public func notifySessionCompleted(sessionId: String, sessionName: String) {
        send(
            title: "Session completed",
            body: "\(sessionName) has finished",
            identifier: "complete-\(sessionId)",
            category: "SESSION_COMPLETE"
        )
    }

    // MARK: - Private

    private func shouldNotify(key: String) -> Bool {
        if let last = lastNotificationTimes[key],
           Date().timeIntervalSince(last) < rateLimitSeconds {
            return false
        }
        lastNotificationTimes[key] = Date()
        return true
    }

    private func send(title: String, body: String, identifier: String, category: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
