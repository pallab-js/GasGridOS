import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private var isAvailable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    private init() {}

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            authorizationStatus = granted ? .authorized : .denied
        } catch {
            print("Notification authorization error: \(error)")
        }
    }

    func checkAuthorization() async {
        guard isAvailable else { return }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let status = settings.authorizationStatus
        authorizationStatus = status
    }

    func sendAlertNotification(alert: Alert) {
        guard isAvailable, authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.subtitle = alert.severity.rawValue
        content.body = alert.message
        content.sound = alert.severity == .critical ? .defaultCritical : .default

        content.userInfo = [
            "alertId": alert.id.uuidString,
            "severity": alert.severity.rawValue
        ]

        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }

    func sendMaintenanceNotification(log: MaintenanceLog) {
        guard isAvailable, authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Maintenance Reminder"
        content.subtitle = log.maintenanceType.rawValue
        content.body = log.description
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: log.id.uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func clearAllNotifications() {
        guard isAvailable else { return }
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func clearNotification(for alertId: UUID) {
        guard isAvailable else { return }
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: [alertId.uuidString])
    }
}
