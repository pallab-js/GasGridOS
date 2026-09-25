import SwiftUI
import Charts

struct FlowRateChartView: View {
    let data: [ChartViewModel.ChartDataPoint]
    let unit: String
    var chartHeight: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Flow Rate Trend")
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
            Image(systemName: "waveform.path.ecg")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No data available")
                .foregroundColor(.secondary)
        }
        .frame(height: chartHeight)
    }

    private var chartContent: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Time", point.timestamp, unit: .hour),
                y: .value("Value", point.value)
            )
            .foregroundStyle(.green)
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    Text("\(value.as(Double.self) ?? 0, specifier: "%.0f")")
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
