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
            errorMessage = nil
        } catch {
            maintenanceLogs = []
            errorMessage = "Failed to load maintenance records: \(error.localizedDescription)"
        }
        categorizeMaintenance()

        isLoading = false
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
