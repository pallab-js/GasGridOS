import Foundation

struct Valve: Identifiable, Codable {
    let id: UUID
    var name: String
    var stationId: UUID
    var valveType: ValveType
    var status: ValveStatus
    var position: Double
    var diameter: Double
    var lastMaintenanceDate: Date?
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        stationId: UUID,
        valveType: ValveType,
        status: ValveStatus = .closed,
        position: Double = 0,
        diameter: Double = 0,
        lastMaintenanceDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.stationId = stationId
        self.valveType = valveType
        self.status = status
        self.position = position
        self.diameter = diameter
        self.lastMaintenanceDate = lastMaintenanceDate
        self.notes = notes
    }
}
