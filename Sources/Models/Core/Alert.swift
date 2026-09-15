import Foundation

struct Alert: Identifiable, Codable {
    let id: UUID
    var stationId: UUID?
    var pipelineId: UUID?
    var severity: AlertSeverity
    var title: String
    var message: String
    var timestamp: Date
    var isAcknowledged: Bool
    var acknowledgedDate: Date?
    var notes: String?

    init(
        id: UUID = UUID(),
        stationId: UUID? = nil,
        pipelineId: UUID? = nil,
        severity: AlertSeverity,
        title: String,
        message: String,
        timestamp: Date = Date(),
        isAcknowledged: Bool = false,
        acknowledgedDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.stationId = stationId
        self.pipelineId = pipelineId
        self.severity = severity
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isAcknowledged = isAcknowledged
        self.acknowledgedDate = acknowledgedDate
        self.notes = notes
    }
}
