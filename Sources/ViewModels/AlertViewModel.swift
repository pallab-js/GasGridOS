import Foundation

@MainActor
final class AlertViewModel: ObservableObject {
    @Published var alerts: [Alert] = []
    @Published var selectedSeverity: AlertSeverity?
    @Published var showUnacknowledgedOnly: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let alertRepo = AlertRepository()

    var filteredAlerts: [Alert] {
        var result = alerts

        if let severity = selectedSeverity {
            result = result.filter { $0.severity == severity }
        }

        if showUnacknowledgedOnly {
            result = result.filter { !$0.isAcknowledged }
        }

        return result.sorted { $0.timestamp > $1.timestamp }
    }

    var unacknowledgedCount: Int {
        alerts.filter { !$0.isAcknowledged }.count
    }

    var criticalCount: Int {
        alerts.filter { !$0.isAcknowledged && $0.severity == .critical }.count
    }

    func loadData() async {
        isLoading = true

        do {
            alerts = try alertRepo.fetchAll()
        } catch {
            errorMessage = "Failed to load alerts: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func acknowledgeAlert(_ alert: Alert, notes: String? = nil) {
        do {
            try alertRepo.acknowledge(alert.id)
            if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
                alerts[index].isAcknowledged = true
                alerts[index].acknowledgedDate = Date()
                if let notes = notes, !notes.isEmpty {
                    alerts[index].notes = notes
                }
            }
        } catch {
            errorMessage = "Failed to acknowledge alert: \(error.localizedDescription)"
        }
    }

    func deleteAlert(_ alert: Alert) {
        do {
            try alertRepo.delete(alert)
            alerts.removeAll { $0.id == alert.id }
            SpotlightService.shared.removeIndex(for: "alert-\(alert.id.uuidString)")
            DatabaseManager.shared.logAuditEvent("DELETE_ALERT", details: "Deleted alert '\(alert.title)' (ID: \(alert.id.uuidString))")
        } catch {
            errorMessage = "Failed to delete alert: \(error.localizedDescription)"
        }
    }
}
