import Foundation
import CoreLocation

struct NetworkStation: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var stationType: StationType
    var status: StationStatus
    var latitude: Double
    var longitude: Double
    var pressure: Double
    var flowRate: Double
    var temperature: Double
    var maximumPressure: Double
    var minimumPressure: Double
    var installedDate: Date
    var lastMaintenanceDate: Date?
    var notes: String?

    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isPressureNormal: Bool {
        pressure >= minimumPressure && pressure <= maximumPressure
    }

    init(
        id: UUID = UUID(),
        name: String,
        stationType: StationType,
        status: StationStatus = .online,
        latitude: Double,
        longitude: Double,
        pressure: Double = 0,
        flowRate: Double = 0,
        temperature: Double = 20,
        maximumPressure: Double = 10,
        minimumPressure: Double = 1,
        installedDate: Date = Date(),
        lastMaintenanceDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.stationType = stationType
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.pressure = pressure
        self.flowRate = flowRate
        self.temperature = temperature
        self.maximumPressure = maximumPressure
        self.minimumPressure = minimumPressure
        self.installedDate = installedDate
        self.lastMaintenanceDate = lastMaintenanceDate
        self.notes = notes
    }
}
