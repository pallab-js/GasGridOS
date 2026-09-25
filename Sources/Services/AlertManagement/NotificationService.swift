import Foundation
@preconcurrency import UserNotifications
import os.log

private let logger = Logger(subsystem: "com.gasgrid", category: "Notification")

extension Notification.Name {
    /// Posted when a notification is tapped so views can navigate to the alert.
    static let gasGridOpenAlert = Notification.Name("com.gasgrid.openAlert")
    /// Posted by the ⌘R shortcut so visible views reload their data.
    static let gasGridRefreshData = Notification.Name("com.gasgrid.refreshData")
}

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Alert ids already announced this session, so re-loading a view never
    /// replays the same notification.
    private var notifiedAlertIds: Set<UUID> = []

    private let notificationDelegate = NotificationDelegate()

    private var isAvailable: Bool {
        // UNUserNotificationCenter traps when the process has no app bundle,
        // which is the case for `swift run` and unit tests. Treat those as
        // "notifications unsupported" instead of crashing.
        Bundle.main.bundleIdentifier != nil && Bundle.main.bundleURL.pathExtension == "app"
    }

    private var center: UNUserNotificationCenter? {
        guard isAvailable else { return nil }
        return UNUserNotificationCenter.current()
    }

    private init() {
        if isAvailable {
            UNUserNotificationCenter.current().delegate = notificationDelegate
        }
    }

    var soundEnabled: Bool {
        UserDefaults.standard.bool(forKey: "enableSoundAlerts")
    }

    var notificationsEnabled: Bool {
        UserDefaults.standard.bool(forKey: "enableNotifications")
    }

    func requestAuthorization() async {
        guard let center else { return }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            authorizationStatus = granted ? .authorized : .denied
        } catch {
            logger.error("Notification authorization error: \(error.localizedDescription)")
        }
    }

    func checkAuthorization() async {
        guard let center else { return }
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func sendAlertNotification(alert: Alert) {
        guard let center, notificationsEnabled else { return }
        guard !notifiedAlertIds.contains(alert.id) else { return }

        switch authorizationStatus {
        case .denied:
            return
        case .notDetermined:
            // Ask now but leave the alert unrecorded so it is announced again
            // once the user grants permission.
            Task { await requestAuthorization() }
            return
        default:
            break
        }

        notifiedAlertIds.insert(alert.id)

        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.subtitle = alert.severity.rawValue
        content.body = alert.message
        content.sound = soundEnabled ? .default : nil

        content.userInfo = [
            "alertId": alert.id.uuidString,
            "severity": alert.severity.rawValue
        ]

        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                logger.error("Error sending notification: \(error.localizedDescription)")
            }
        }
    }

    func sendMaintenanceNotification(log: MaintenanceLog) {
        guard let center, notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Maintenance Reminder"
        content.subtitle = log.maintenanceType.rawValue
        content.body = log.description
        content.sound = soundEnabled ? .default : nil

        let request = UNNotificationRequest(
            identifier: log.id.uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                logger.error("Error sending maintenance notification: \(error.localizedDescription)")
            }
        }
    }

    func clearAllNotifications() {
        guard let center else { return }
        notifiedAlertIds.removeAll()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    func clearNotification(for alertId: UUID) {
        guard let center else { return }
        notifiedAlertIds.remove(alertId)
        center.removeDeliveredNotifications(withIdentifiers: [alertId.uuidString])
    }
}

private final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: .gasGridOpenAlert, object: nil, userInfo: userInfo)
        completionHandler()
    }
}
