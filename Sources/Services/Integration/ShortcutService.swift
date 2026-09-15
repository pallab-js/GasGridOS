import Foundation

@MainActor
final class ShortcutService {
    static let shared = ShortcutService()

    private init() {}

    func donateShortcuts(stations: [NetworkStation]) {
        for station in stations.prefix(5) {
            let userActivity = NSUserActivity(activityType: "com.gasgrid.viewStation")
            userActivity.userInfo = ["stationId": station.id.uuidString]
            userActivity.title = "View \(station.name)"
            userActivity.becomeCurrent()
        }
    }
}
