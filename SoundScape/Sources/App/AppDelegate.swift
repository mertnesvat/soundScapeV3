import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // Notification names for inter-service communication
    static let alarmFiredNotification = Notification.Name("AlarmFired")
    static let alarmActionNotification = Notification.Name("AlarmAction")

    // UserInfo keys
    static let alarmIdKey = "alarmId"
    static let actionTypeKey = "actionType"

    enum AlarmActionType: String {
        case fired
        case snooze
        case stop
    }

    // MARK: - UIApplicationDelegate

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        registerAlarmCategory(with: center)
        return true
    }

    // MARK: - Category Registration

    private func registerAlarmCategory(with center: UNUserNotificationCenter) {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze",
            options: [.foreground]
        )

        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "Stop",
            options: [.destructive, .foreground]
        )

        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([alarmCategory])
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when the user taps a notification or selects an action button
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        guard let alarmId = parseAlarmId(from: identifier) else {
            completionHandler()
            return
        }

        // Cancel remaining chain notifications for this alarm
        cancelChainNotifications(for: alarmId, center: center)

        let actionType: AlarmActionType
        switch response.actionIdentifier {
        case "SNOOZE_ACTION":
            actionType = .snooze
        case "STOP_ACTION":
            actionType = .stop
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself → treat as "alarm fired, open app"
            actionType = .fired
        default:
            completionHandler()
            return
        }

        NotificationCenter.default.post(
            name: AppDelegate.alarmActionNotification,
            object: nil,
            userInfo: [
                AppDelegate.alarmIdKey: alarmId,
                AppDelegate.actionTypeKey: actionType.rawValue,
            ]
        )

        completionHandler()
    }

    /// Called when a notification arrives while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let identifier = notification.request.identifier
        guard let alarmId = parseAlarmId(from: identifier) else {
            completionHandler([.banner, .sound])
            return
        }

        // Post "alarm fired" event so AlarmService can show the ringing UI
        NotificationCenter.default.post(
            name: AppDelegate.alarmFiredNotification,
            object: nil,
            userInfo: [AppDelegate.alarmIdKey: alarmId]
        )

        // Show banner + play sound even in foreground
        completionHandler([.banner, .sound])
    }

    // MARK: - Helpers

    /// Extracts the alarm UUID string from notification identifiers.
    /// Handles formats: "{uuid}", "{uuid}_chain_{n}", "{uuid}_day_{n}_chain_{n}", "{uuid}_snooze", "{uuid}_snooze_chain_{n}"
    private func parseAlarmId(from identifier: String) -> String? {
        // The alarm UUID is always the first 36 characters (standard UUID format)
        let uuidLength = 36
        guard identifier.count >= uuidLength else { return nil }

        let candidate = String(identifier.prefix(uuidLength))
        // Validate it looks like a UUID
        guard UUID(uuidString: candidate) != nil else { return nil }
        return candidate
    }

    /// Cancels all pending chain notifications for the given alarm UUID
    private func cancelChainNotifications(for alarmId: String, center: UNUserNotificationCenter) {
        center.getPendingNotificationRequests { requests in
            let matching = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(alarmId) }
            if !matching.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: matching)
            }
        }
    }
}
