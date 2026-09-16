import SwiftUI

struct SystemStatusView: View {
    let stations: [NetworkStation]
    let pipelines: [Pipeline]
    let sensors: [Sensor]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Status")
                .font(.headline)

            HStack(spacing: 20) {
                StatusItem(
                    title: "Stations",
                    online: stations.filter { $0.status == .online }.count,
                    total: stations.count,
                    icon: "antenna.radiowaves.left.and.right"
                )

                StatusItem(
                    title: "Pipelines",
                    online: pipelines.count,
                    total: pipelines.count,
                    icon: "cable.connector"
                )

                StatusItem(
                    title: "Sensors",
                    online: sensors.filter { $0.isOnline }.count,
                    total: sensors.count,
                    icon: "sensor.fill"
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct StatusItem: View {
    let title: String
    let online: Int
    let total: Int
    let icon: String

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(online) / Double(total)
    }

    var statusColor: Color {
        if percentage >= 0.9 { return .green }
        if percentage >= 0.7 { return .yellow }
        return .red
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(statusColor)

            Text("\(online)/\(total)")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            ProgressView(value: percentage)
                .tint(statusColor)
                .accessibilityLabel("\(title) status: \(online) of \(total) online")
        }
        .frame(maxWidth: .infinity)
    }
}
