import SwiftUI
import Charts

struct TemperatureChartView: View {
    let data: [ChartViewModel.ChartDataPoint]
    let unit: String
    var chartHeight: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Temperature Trend")
                    .font(.headline)
                Spacer()
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if data.isEmpty {
                noDataView
            } else {
                chartContent
            }
        }
        .cardStyle()
    }

    private var noDataView: some View {
        VStack {
            Image(systemName: "thermometer.medium")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No data available")
                .foregroundColor(.secondary)
        }
        .frame(height: chartHeight)
    }

    private var chartContent: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Value", point.value)
            )
            .foregroundStyle(.orange)
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Time", point.timestamp),
                y: .value("Value", point.value)
            )
            .foregroundStyle(.orange)
            .symbolSize(30)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    Text("\(value.as(Double.self) ?? 0, specifier: "%.1f")")
                        .font(.caption2)
                }
                AxisGridLine()
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: max(1, data.count / 6))) { value in
                AxisValueLabel {
                    Text(value.as(Date.self) ?? Date(), format: .dateTime.hour().minute())
                        .font(.caption2)
                }
            }
        }
        .chartYScale(domain: (data.map(\.value).min() ?? 0)...(data.map(\.value).max() ?? 1))
        .frame(height: chartHeight)
    }
}
