import Foundation
import CoreLocation

struct Pipeline: Identifiable, Codable {
    let id: UUID
    var name: String
    var startStationId: UUID
    var endStationId: UUID
    var startLatitude: Double
    var startLongitude: Double
    var endLatitude: Double
    var endLongitude: Double
    var diameter: Double
    var material: PipelineMaterial
    var pressure: Double
    var length: Double
    var installedDate: Date
    var lastInspectionDate: Date?
    var notes: String?

    var startLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    }

    var endLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        startStationId: UUID,
        endStationId: UUID,
        startLatitude: Double,
        startLongitude: Double,
        endLatitude: Double,
        endLongitude: Double,
        diameter: Double,
        material: PipelineMaterial,
        pressure: Double = 0,
        length: Double = 0,
        installedDate: Date = Date(),
        lastInspectionDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.startStationId = startStationId
        self.endStationId = endStationId
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.diameter = diameter
        self.material = material
        self.pressure = pressure
        self.length = length
        self.installedDate = installedDate
        self.lastInspectionDate = lastInspectionDate
        self.notes = notes
    }
}
