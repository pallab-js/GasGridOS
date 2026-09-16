import SwiftUI

struct StationPerformanceView: View {
    let stations: [NetworkStation]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(stations) { station in
                    StationPerformanceCard(station: station)
                }
            }
        }
        .accessibilityLabel("Station performance cards")
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct StationPerformanceCard: View {
    let station: NetworkStation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: station.stationType.icon)
                    .foregroundColor(.blue)
                Spacer()
                StatusBadge(
                    text: station.status.rawValue,
                    color: station.status.color,
                    icon: station.status.icon
                )
            }

            Text(station.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                PerformanceRow(label: "Pressure", value: String(format: "%.2f bar", station.pressure))
                PerformanceRow(label: "Flow", value: String(format: "%.1f m³/h", station.flowRate))
                PerformanceRow(label: "Temp", value: String(format: "%.1f°C", station.temperature))
            }
        }
        .padding()
        .frame(width: 180)
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PerformanceRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}
