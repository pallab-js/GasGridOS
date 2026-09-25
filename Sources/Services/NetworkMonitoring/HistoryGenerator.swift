import Foundation
import os.log

private let logger = Logger(subsystem: "com.gasgrid", category: "HistoryGenerator")

@MainActor
final class HistoryGenerator {
    static let shared = HistoryGenerator()

    private let historyRepo = DataHistoryRepository()
    private let sensorRepo = SensorRepository()

    private init() {}

    /// Generates one week of hourly telemetry for every station that has sensors.
    /// Safe to call repeatedly: readings outside the retention window are pruned
    /// first and stations without the required sensors are skipped rather than
    /// given fabricated ids.
    func generateHistoryData(for stations: [NetworkStation], days: Int = 7) {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: now) else { return }

        do {
            try historyRepo.deleteOlderThan(startDate)
        } catch {
            logger.error("Error pruning old readings: \(error.localizedDescription)")
        }

        var readings: [SensorReading] = []

        for station in stations {
            guard let sensors = try? sensorRepo.fetchByStation(station.id) else {
                logger.error("Skipping history for \(station.name): sensors could not be loaded")
                continue
            }
            guard let pressureSensor = sensors.first(where: { $0.sensorType == .pressure }),
                  let flowSensor = sensors.first(where: { $0.sensorType == .flowRate }),
                  let tempSensor = sensors.first(where: { $0.sensorType == .temperature }) else {
                continue
            }

            var currentDate = startDate
            while currentDate <= now {
                readings.append(createReading(
                    sensorId: pressureSensor.id,
                    type: .pressure,
                    baseValue: station.pressure,
                    variance: 0.3,
                    timestamp: currentDate
                ))
                readings.append(createReading(
                    sensorId: flowSensor.id,
                    type: .flowRate,
                    baseValue: station.flowRate,
                    variance: 10.0,
                    timestamp: currentDate.addingTimeInterval(60)
                ))
                readings.append(createReading(
                    sensorId: tempSensor.id,
                    type: .temperature,
                    baseValue: station.temperature,
                    variance: 2.0,
                    timestamp: currentDate.addingTimeInterval(120)
                ))

                guard let nextHour = calendar.date(byAdding: .hour, value: 1, to: currentDate) else { break }
                currentDate = nextHour
            }
        }

        do {
            try historyRepo.insertBatch(readings)
        } catch {
            logger.error("Error generating history: \(error.localizedDescription)")
        }
    }

    private func createReading(sensorId: UUID, type: SensorType, baseValue: Double, variance: Double, timestamp: Date) -> SensorReading {
        let hour = Calendar.current.component(.hour, from: timestamp)
        let timeMultiplier = getTimeMultiplier(for: hour)
        let randomVariation = Double.random(in: -variance...variance)
        let value = baseValue * timeMultiplier + randomVariation

        return SensorReading(
            sensorId: sensorId,
            value: max(0, value),
            unit: type.unit,
            timestamp: timestamp
        )
    }

    private func getTimeMultiplier(for hour: Int) -> Double {
        switch hour {
        case 0..<6: return 0.7
        case 6..<9: return 1.0
        case 9..<12: return 1.2
        case 12..<14: return 1.1
        case 14..<18: return 1.3
        case 18..<21: return 1.0
        case 21..<24: return 0.8
        default: return 1.0
        }
    }

    func fetchChartData(for stationId: UUID, type: SensorType, timeRange: ChartViewModel.TimeRange) async -> [ChartViewModel.ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .hour, value: -Int(timeRange.hours), to: now) else { return [] }

        do {
            let sensors = try sensorRepo.fetchByStation(stationId)
            let sensorIds = Set(sensors.filter { $0.sensorType == type }.map(\.id))
            guard !sensorIds.isEmpty else { return [] }

            let readings = try historyRepo.fetchByTimeRange(startDate: startDate, endDate: now)
            let filteredReadings = readings.filter { reading in
                sensorIds.contains(reading.sensorId) && reading.unit == type.unit
            }

            return filteredReadings.map { reading in
                ChartViewModel.ChartDataPoint(
                    timestamp: reading.timestamp,
                    value: reading.value,
                    label: ""
                )
            }
        } catch {
            logger.error("Error fetching chart data: \(error.localizedDescription)")
            return []
        }
    }
}
