import SwiftUI

struct NetworkOverviewView: View {
    let stations: [NetworkStation]
    let pipelines: [Pipeline]
    var isCompact: Bool = false

    var totalPipelineLength: Double {
        pipelines.reduce(0) { $0 + $1.length }
    }

    var averagePressure: Double {
        guard !stations.isEmpty else { return 0 }
        return stations.reduce(0) { $0 + $1.pressure } / Double(stations.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: isCompact
                ? [GridItem(.adaptive(minimum: 150))]
                : [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12) {
                OverviewStatCard(
                    title: "Total Stations",
                    value: "\(stations.count)",
                    icon: "building.2.fill",
                    color: .blue
                )

                OverviewStatCard(
                    title: "Online",
                    value: "\(stations.filter { $0.status == .online }.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                OverviewStatCard(
                    title: "Pipeline Length",
                    value: String(format: "%.1f km", totalPipelineLength),
                    icon: "ruler.fill",
                    color: .purple
                )

                OverviewStatCard(
                    title: "Avg Pressure",
                    value: String(format: "%.2f bar", averagePressure),
                    icon: "gauge.medium",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct OverviewStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
