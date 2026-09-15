import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

@MainActor
@preconcurrency
final class SpotlightService {
    static let shared = SpotlightService()

    private let searchQueue = DispatchQueue(label: "com.gasgrid.spotlight", qos: .userInitiated)

    private init() {}

    func indexStations(_ stations: [NetworkStation]) {
        let items: [CSSearchableItem] = stations.map { station in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
            attributeSet.title = station.name
            attributeSet.contentDescription = "\(station.stationType.rawValue) - \(station.status.rawValue)"

            return CSSearchableItem(
                uniqueIdentifier: "station-\(station.id.uuidString)",
                domainIdentifier: "com.gasgrid.stations",
                attributeSet: attributeSet
            )
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("Spotlight indexing error: \(error)")
            }
        }
    }

    func indexAlerts(_ alerts: [Alert]) {
        let items: [CSSearchableItem] = alerts.map { alert in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
            attributeSet.title = alert.title
            attributeSet.contentDescription = alert.message

            return CSSearchableItem(
                uniqueIdentifier: "alert-\(alert.id.uuidString)",
                domainIdentifier: "com.gasgrid.alerts",
                attributeSet: attributeSet
            )
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("Spotlight alert indexing error: \(error)")
            }
        }
    }

    func indexPipelines(_ pipelines: [Pipeline]) {
        let items: [CSSearchableItem] = pipelines.map { pipeline in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
            attributeSet.title = pipeline.name
            attributeSet.contentDescription = "\(pipeline.material.rawValue) - \(pipeline.diameter)mm"

            return CSSearchableItem(
                uniqueIdentifier: "pipeline-\(pipeline.id.uuidString)",
                domainIdentifier: "com.gasgrid.pipelines",
                attributeSet: attributeSet
            )
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("Spotlight pipeline indexing error: \(error)")
            }
        }
    }

    func removeIndex(for identifier: String) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier]) { error in
            if let error = error {
                print("Spotlight removal error: \(error)")
            }
        }
    }

    func clearAllIndices() {
        CSSearchableIndex.default().deleteAllSearchableItems { error in
            if let error = error {
                print("Spotlight clear error: \(error)")
            }
        }
    }
}
