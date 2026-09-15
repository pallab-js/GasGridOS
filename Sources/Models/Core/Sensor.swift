import Foundation

struct Sensor: Identifiable, Codable {
    let id: UUID
    var name: String
    var stationId: UUID
    var sensorType: SensorType
    var isOnline: Bool
    var lastReading: Double?
    var lastReadingDate: Date?
    var minimumValue: Double?
    var maximumValue: Double?
    var installedDate: Date

    var statusIcon: String {
        isOnline ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    init(
        id: UUID = UUID(),
        name: String,
        stationId: UUID,
        sensorType: SensorType,
        isOnline: Bool = true,
        lastReading: Double? = nil,
        lastReadingDate: Date? = nil,
        minimumValue: Double? = nil,
        maximumValue: Double? = nil,
        installedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.stationId = stationId
        self.sensorType = sensorType
        self.isOnline = isOnline
        self.lastReading = lastReading
        self.lastReadingDate = lastReadingDate
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        self.installedDate = installedDate
    }
}
