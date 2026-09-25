import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var stations: [NetworkStation] = []
    @Published var alerts: [Alert] = []
    @Published var pipelines: [Pipeline] = []
    @Published var sensors: [Sensor] = []

    @Published var totalStations: Int = 0
    @Published var onlineStations: Int = 0
    @Published var offlineStations: Int = 0
    @Published var criticalAlerts: Int = 0
    @Published var warningAlerts: Int = 0
    @Published var totalPipelineLength: Double = 0

    @Published var averagePressure: Double = 0
    @Published var averageFlowRate: Double = 0
    @Published var averageTemperature: Double = 0

    @Published var pressureTrend: Double = 0
    @Published var flowRateTrend: Double = 0
    @Published var temperatureTrend: Double = 0

    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date = Date()
    @Published var errorMessage: String?

    private let stationRepo = StationRepository()
    private let pipelineRepo = PipelineRepository()
    private let alertRepo = AlertRepository()
    private let sensorRepo = SensorRepository()
    private let spotlightService = SpotlightService.shared
    private let notificationService = NotificationService.shared
    private let shortcutService = ShortcutService.shared

    private var previousPressure: Double = 0
    private var previousFlowRate: Double = 0
    private var previousTemperature: Double = 0

    func loadData() async {
        isLoading = true

        previousPressure = averagePressure
        previousFlowRate = averageFlowRate
        previousTemperature = averageTemperature

        do {
            stations = try stationRepo.fetchAll()
            pipelines = try pipelineRepo.fetchAll()
            alerts = try alertRepo.fetchAll()
            sensors = try sensorRepo.fetchAll()

            calculateStatistics()
            calculateTrends()
            lastUpdated = Date()

            await indexDataForSpotlight()
            await checkAlertNotifications()
        } catch {
            errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func calculateStatistics() {
        totalStations = stations.count
        onlineStations = stations.filter { $0.status == .online }.count
        offlineStations = stations.filter { $0.status == .offline }.count

        let unacknowledgedAlerts = alerts.filter { !$0.isAcknowledged }
        criticalAlerts = unacknowledgedAlerts.filter { $0.severity == .critical }.count
        warningAlerts = unacknowledgedAlerts.filter { $0.severity == .high || $0.severity == .medium }.count

        totalPipelineLength = pipelines.reduce(0) { $0 + $1.length }

        if !stations.isEmpty {
            averagePressure = stations.reduce(0) { $0 + $1.pressure } / Double(stations.count)
            averageFlowRate = stations.reduce(0) { $0 + $1.flowRate } / Double(stations.count)
            averageTemperature = stations.reduce(0) { $0 + $1.temperature } / Double(stations.count)
        } else {
            averagePressure = 0
            averageFlowRate = 0
            averageTemperature = 0
            pressureTrend = 0
            flowRateTrend = 0
            temperatureTrend = 0
        }
    }

    private func calculateTrends() {
        guard !stations.isEmpty else { return }

        if previousPressure > 0 {
            pressureTrend = averagePressure - previousPressure
        }
        if previousFlowRate > 0 {
            flowRateTrend = averageFlowRate - previousFlowRate
        }
        if previousTemperature > 0 {
            temperatureTrend = averageTemperature - previousTemperature
        }
    }

    private func indexDataForSpotlight() async {
        spotlightService.indexStations(stations)
        spotlightService.indexPipelines(pipelines)
        spotlightService.indexAlerts(alerts)
        shortcutService.donateShortcuts(stations: stations)
    }

    private func checkAlertNotifications() async {
        let unacknowledgedCritical = alerts.filter { !$0.isAcknowledged && $0.severity == .critical }
        for alert in unacknowledgedCritical {
            notificationService.sendAlertNotification(alert: alert)
        }
    }
}
