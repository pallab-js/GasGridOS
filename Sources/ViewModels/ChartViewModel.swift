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
        errorMessage = nil

        let range = timeRange ?? selectedTimeRange
        let calendar = Calendar.current
        let now = Date()
        guard calendar.date(byAdding: .hour, value: -Int(range.hours), to: now) != nil else {
            isLoading = false
            return
        }

        let stations: [NetworkStation]
        do {
            stations = try StationRepository().fetchAll()
        } catch {
            pressureHistory = []
            flowRateHistory = []
            temperatureHistory = []
            errorMessage = "Failed to load chart data: \(error.localizedDescription)"
            isLoading = false
            return
        }

        if let targetStationId = stationId {
            pressureHistory = await HistoryGenerator.shared.fetchChartData(for: targetStationId, type: .pressure, timeRange: range)
            flowRateHistory = await HistoryGenerator.shared.fetchChartData(for: targetStationId, type: .flowRate, timeRange: range)
            temperatureHistory = await HistoryGenerator.shared.fetchChartData(for: targetStationId, type: .temperature, timeRange: range)
        } else if let firstStation = stations.first {
            pressureHistory = await HistoryGenerator.shared.fetchChartData(for: firstStation.id, type: .pressure, timeRange: range)
            flowRateHistory = await HistoryGenerator.shared.fetchChartData(for: firstStation.id, type: .flowRate, timeRange: range)
            temperatureHistory = await HistoryGenerator.shared.fetchChartData(for: firstStation.id, type: .temperature, timeRange: range)
        } else {
            pressureHistory = []
            flowRateHistory = []
            temperatureHistory = []
        }

        isLoading = false
    }
}
