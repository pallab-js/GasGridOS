import Foundation

@MainActor
final class MaintenanceViewModel: ObservableObject {
    @Published var maintenanceLogs: [MaintenanceLog] = []
    @Published var upcomingMaintenance: [MaintenanceLog] = []
    @Published var overdueMaintenance: [MaintenanceLog] = []
    @Published var completedMaintenance: [MaintenanceLog] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedFilter: MaintenanceFilter = .all

    private let maintenanceRepo = MaintenanceRepository()

    enum MaintenanceFilter: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case overdue = "Overdue"
        case completed = "Completed"
    }

    var filteredLogs: [MaintenanceLog] {
        switch selectedFilter {
        case .all:
            return maintenanceLogs
        case .upcoming:
            return upcomingMaintenance
        case .overdue:
            return overdueMaintenance
        case .completed:
            return completedMaintenance
        }
    }

    func loadData() async {
        isLoading = true

        do {
            maintenanceLogs = try maintenanceRepo.fetchAll()
        } catch {
            maintenanceLogs = fetchSampleData()
        }
        categorizeMaintenance()

        isLoading = false
    }

    private func fetchSampleData() -> [MaintenanceLog] {
        let calendar = Calendar.current
        let now = Date()

        return [
            MaintenanceLog(
                assetId: UUID(),
                assetType: "Station",
                maintenanceType: .preventive,
                description: "Annual pressure calibration - Central Hub",
                scheduledDate: calendar.date(byAdding: .day, value: 7, to: now) ?? now,
                performedBy: "John Smith"
            ),
            MaintenanceLog(
                assetId: UUID(),
                assetType: "Pipeline",
                maintenanceType: .inspection,
                description: "Pipeline integrity inspection - Main Line",
                scheduledDate: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                performedBy: "Jane Doe"
            ),
            MaintenanceLog(
                assetId: UUID(),
                assetType: "Valve",
                maintenanceType: .corrective,
                description: "Valve stem replacement - North Station",
                scheduledDate: calendar.date(byAdding: .day, value: 14, to: now) ?? now,
                performedBy: "Mike Johnson"
            ),
            MaintenanceLog(
                assetId: UUID(),
                assetType: "Sensor",
                maintenanceType: .preventive,
                description: "Sensor calibration check - Pressure Sensors",
                scheduledDate: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                completedDate: calendar.date(byAdding: .day, value: -1, to: now),
                performedBy: "Sarah Wilson",
                cost: 250.00
            ),
            MaintenanceLog(
                assetId: UUID(),
                assetType: "Station",
                maintenanceType: .emergency,
                description: "Emergency valve repair - South Station",
                scheduledDate: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                completedDate: now,
                performedBy: "Tom Brown",
                cost: 1500.00
            ),
            MaintenanceLog(
                assetId: UUID(),
                assetType: "Pipeline",
                maintenanceType: .predictive,
                description: "Leak detection survey - Distribution Network",
                scheduledDate: calendar.date(byAdding: .day, value: 21, to: now) ?? now,
                performedBy: "Lisa Chen"
            ),
            MaintenanceLog(
                assetId: UUID(),
                assetType: "Valve",
                maintenanceType: .inspection,
                description: "Quarterly valve inspection - All Stations",
                scheduledDate: calendar.date(byAdding: .day, value: 30, to: now) ?? now,
                performedBy: "David Park"
            )
        ]
    }

    private func categorizeMaintenance() {
        let now = Date()
        upcomingMaintenance = maintenanceLogs.filter { !$0.isCompleted && $0.scheduledDate > now }
        overdueMaintenance = maintenanceLogs.filter { $0.isOverdue }
        completedMaintenance = maintenanceLogs.filter { $0.isCompleted }
    }

    func addMaintenanceLog(_ log: MaintenanceLog) {
        do {
            try maintenanceRepo.insert(log)
            maintenanceLogs.append(log)
            categorizeMaintenance()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    func updateMaintenanceLog(_ log: MaintenanceLog) {
        do {
            try maintenanceRepo.update(log)
            if let index = maintenanceLogs.firstIndex(where: { $0.id == log.id }) {
                maintenanceLogs[index] = log
                categorizeMaintenance()
            }
        } catch {
            errorMessage = "Failed to update: \(error.localizedDescription)"
        }
    }

    func completeMaintenance(_ log: MaintenanceLog) {
        var updated = log
        updated.completedDate = Date()
        do {
            try maintenanceRepo.update(updated)
            if let index = maintenanceLogs.firstIndex(where: { $0.id == log.id }) {
                maintenanceLogs[index].completedDate = Date()
                categorizeMaintenance()
            }
        } catch {
            errorMessage = "Failed to complete: \(error.localizedDescription)"
        }
    }

    func deleteMaintenanceLog(_ log: MaintenanceLog) {
        do {
            try maintenanceRepo.delete(log)
            maintenanceLogs.removeAll { $0.id == log.id }
            categorizeMaintenance()
            DatabaseManager.shared.logAuditEvent("DELETE_MAINTENANCE", details: "Deleted maintenance task '\(log.description)' (ID: \(log.id.uuidString))")
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }
}
