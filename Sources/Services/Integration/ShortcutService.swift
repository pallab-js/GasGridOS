import Foundation

@MainActor
final class ShortcutService {
    static let shared = ShortcutService()

    private var currentActivity: NSUserActivity?

    private init() {}

    func donateShortcuts(stations: [NetworkStation]) {
        guard let station = stations.first else { return }

        currentActivity?.invalidate()

        let userActivity = NSUserActivity(activityType: "com.gasgrid.viewStation")
        userActivity.userInfo = ["stationId": station.id.uuidString]
        userActivity.title = "View \(station.name)"
        userActivity.isEligibleForSearch = true
        userActivity.persistentIdentifier = station.id.uuidString

        currentActivity = userActivity
        userActivity.becomeCurrent()
    }

    func invalidate() {
        currentActivity?.invalidate()
        currentActivity = nil
    }
}
