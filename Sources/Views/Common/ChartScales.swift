import Foundation

/// Scale domains for the dashboard charts. Charts can't infer a usable range
/// when every sample is identical (flat line) or when there is only one
/// timestamp, so both cases get an explicit, non-degenerate range.
enum ChartScales {
    static func yDomain(for points: [ChartViewModel.ChartDataPoint]) -> ClosedRange<Double> {
        let values = points.map(\.value)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...1
        }
        guard maxValue > minValue else {
            let padding = max(abs(minValue) * 0.1, 1)
            return (minValue - padding)...(minValue + padding)
        }
        return minValue...maxValue
    }

    static func xDomain(for points: [ChartViewModel.ChartDataPoint]) -> ClosedRange<Date> {
        let timestamps = points.map(\.timestamp)
        guard let first = timestamps.min(), let last = timestamps.max() else {
            let now = Date()
            return now.addingTimeInterval(-3600)...now
        }
        guard last > first else {
            return first.addingTimeInterval(-1800)...first.addingTimeInterval(1800)
        }
        // Half-hour margins keep the first and last hourly bar from clipping.
        return first.addingTimeInterval(-1800)...last.addingTimeInterval(1800)
    }
}
