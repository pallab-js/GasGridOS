import SwiftUI
import Charts

struct PressureChartView: View {
    let data: [ChartViewModel.ChartDataPoint]
    let unit: String
    var chartHeight: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pressure Trend")
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
            Image(systemName: "chart.line.uptrend.xyaxis")
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
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value("Value", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
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
        .chartYScale(domain: ChartScales.yDomain(for: data))
        .chartXScale(domain: ChartScales.xDomain(for: data))
        .frame(height: chartHeight)
    }
}
