import Foundation

struct MaintenanceLog: Identifiable, Codable {
    let id: UUID
    var assetId: UUID
    var assetType: String
    var maintenanceType: MaintenanceType
    var description: String
    var scheduledDate: Date
    var completedDate: Date?
    var performedBy: String?
    var cost: Double?
    var notes: String?

    var isCompleted: Bool {
        completedDate != nil
    }

    var isOverdue: Bool {
        !isCompleted && scheduledDate < Date()
    }

    init(
        id: UUID = UUID(),
        assetId: UUID,
        assetType: String,
        maintenanceType: MaintenanceType,
        description: String,
        scheduledDate: Date,
        completedDate: Date? = nil,
        performedBy: String? = nil,
        cost: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.assetId = assetId
        self.assetType = assetType
        self.maintenanceType = maintenanceType
        self.description = description
        self.scheduledDate = scheduledDate
        self.completedDate = completedDate
        self.performedBy = performedBy
        self.cost = cost
        self.notes = notes
    }
}
