import Foundation

struct SensorReading: Identifiable, Codable {
    let id: UUID
    var sensorId: UUID
    var value: Double
    var unit: String
    var timestamp: Date
    var isAboveThreshold: Bool
    var isBelowThreshold: Bool

    init(
        id: UUID = UUID(),
        sensorId: UUID,
        value: Double,
        unit: String,
        timestamp: Date = Date(),
        isAboveThreshold: Bool = false,
        isBelowThreshold: Bool = false
    ) {
        self.id = id
        self.sensorId = sensorId
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
        self.isAboveThreshold = isAboveThreshold
        self.isBelowThreshold = isBelowThreshold
    }
}
