import Foundation

@MainActor
final class HistoryGenerator {
    static let shared = HistoryGenerator()

    private let historyRepo = DataHistoryRepository()

    private init() {}

    func generateHistoryData(for stations: [NetworkStation], days: Int = 7) {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: now) else { return }

        var readings: [SensorReading] = []

        for station in stations {
            var currentDate = startDate
            while currentDate <= now {
                let pressureReading = createReading(
                    sensorId: station.id,
                    type: .pressure,
                    baseValue: station.pressure,
                    variance: 0.3,
                    timestamp: currentDate
                )
                readings.append(pressureReading)

                let flowReading = createReading(
                    sensorId: station.id,
                    type: .flowRate,
                    baseValue: station.flowRate,
                    variance: 10.0,
                    timestamp: currentDate.addingTimeInterval(60)
                )
                readings.append(flowReading)

                let tempReading = createReading(
                    sensorId: station.id,
                    type: .temperature,
                    baseValue: station.temperature,
                    variance: 2.0,
                    timestamp: currentDate.addingTimeInterval(120)
                )
                readings.append(tempReading)

                currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
            }
        }

        do {
            try historyRepo.insertBatch(readings)
        } catch {
            print("Error generating history: \(error)")
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
            let readings = try historyRepo.fetchByTimeRange(startDate: startDate, endDate: now)
            let filteredReadings = readings.filter { reading in
                reading.sensorId == stationId && reading.unit == type.unit
            }

            return filteredReadings.map { reading in
                ChartViewModel.ChartDataPoint(
                    timestamp: reading.timestamp,
                    value: reading.value,
                    label: ""
                )
            }
        } catch {
            print("Error fetching chart data: \(error)")
            return []
        }
    }
}
