import Foundation
import SwiftUI

@MainActor
final class RealTimeSimulator: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var lastUpdate: Date = Date()
    @Published var errorMessage: String?

    private var timer: Timer?
    private let stationRepo = StationRepository()
    private let sensorRepo = SensorRepository()
    private let alertRepo = AlertRepository()

    var onAlertGenerated: ((Alert) -> Void)?

    func startSimulation() {
        guard !isRunning else { return }
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.simulateDataUpdate()
            }
        }
    }

    func stopSimulation() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func simulateDataUpdate() {
        do {
            var stations = try stationRepo.fetchAll()

            for index in 0..<stations.count {
                var station = stations[index]

                let pressureVariation = Double.random(in: -0.2...0.2)
                station.pressure = max(0, station.pressure + pressureVariation)

                let flowVariation = Double.random(in: -5.0...5.0)
                station.flowRate = max(0, station.flowRate + flowVariation)

                let tempVariation = Double.random(in: -0.5...0.5)
                station.temperature = station.temperature + tempVariation

                if station.pressure > station.maximumPressure {
                    generateAlert(
                        stationId: station.id,
                        severity: .critical,
                        title: "High Pressure Alert",
                        message: "Pressure \(String(format: "%.2f", station.pressure)) bar exceeds maximum \(String(format: "%.2f", station.maximumPressure)) bar at \(station.name)"
                    )
                } else if station.pressure < station.minimumPressure {
                    generateAlert(
                        stationId: station.id,
                        severity: .high,
                        title: "Low Pressure Alert",
                        message: "Pressure \(String(format: "%.2f", station.pressure)) bar below minimum \(String(format: "%.2f", station.minimumPressure)) bar at \(station.name)"
                    )
                }

                if station.temperature > 40 {
                    generateAlert(
                        stationId: station.id,
                        severity: .medium,
                        title: "High Temperature Warning",
                        message: "Temperature \(String(format: "%.1f", station.temperature))°C is elevated at \(station.name)"
                    )
                }

                stations[index] = station
            }

            try stationRepo.updateBatch(stations)
            lastUpdate = Date()
        } catch {
            errorMessage = "Simulation error: \(error.localizedDescription)"
        }
    }

    private func generateAlert(stationId: UUID, severity: AlertSeverity, title: String, message: String) {
        let alert = Alert(
            stationId: stationId,
            severity: severity,
            title: title,
            message: message
        )

        do {
            try alertRepo.insert(alert)
            onAlertGenerated?(alert)
        } catch {
            errorMessage = "Error generating alert: \(error.localizedDescription)"
        }
    }
}
