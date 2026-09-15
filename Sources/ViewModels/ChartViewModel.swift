import Foundation
import SwiftUI

@MainActor
final class ChartViewModel: ObservableObject {
    @Published var pressureHistory: [ChartDataPoint] = []
    @Published var flowRateHistory: [ChartDataPoint] = []
    @Published var temperatureHistory: [ChartDataPoint] = []
    @Published var selectedTimeRange: TimeRange = .lastHour
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    enum TimeRange: String, CaseIterable, Identifiable {
        case lastHour = "1H"
        case last6Hours = "6H"
        case last24Hours = "24H"
        case lastWeek = "1W"
        case lastMonth = "1M"

        var id: String { rawValue }

        var hours: Double {
            switch self {
            case .lastHour: return 1
            case .last6Hours: return 6
            case .last24Hours: return 24
            case .lastWeek: return 168
            case .lastMonth: return 720
            }
        }
    }

    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let timestamp: Date
        let value: Double
        let label: String
    }

    func loadHistoricalData(for stationId: UUID? = nil, timeRange: TimeRange? = nil) async {
        isLoading = true

        let range = timeRange ?? selectedTimeRange
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .hour, value: -Int(range.hours), to: now) else {
            isLoading = false
            return
        }

        pressureHistory = generateSampleData(startDate: startDate, endDate: now, baseValue: 4.0, variance: 0.5, timeRange: range)
        flowRateHistory = generateSampleData(startDate: startDate, endDate: now, baseValue: 120.0, variance: 20.0, timeRange: range)
        temperatureHistory = generateSampleData(startDate: startDate, endDate: now, baseValue: 25.0, variance: 5.0, timeRange: range)

        isLoading = false
    }

    private func generateSampleData(startDate: Date, endDate: Date, baseValue: Double, variance: Double, timeRange: TimeRange) -> [ChartDataPoint] {
        var points: [ChartDataPoint] = []
        let calendar = Calendar.current
        let hourInterval = max(1, Int(timeRange.hours / 24))

        var currentDate = startDate
        while currentDate <= endDate {
            let randomOffset = Double.random(in: -variance...variance)
            let value = baseValue + randomOffset
            points.append(ChartDataPoint(timestamp: currentDate, value: value, label: ""))
            currentDate = calendar.date(byAdding: .hour, value: hourInterval, to: currentDate) ?? currentDate
        }

        return points
    }
}
