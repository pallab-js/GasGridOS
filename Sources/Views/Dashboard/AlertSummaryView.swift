import SwiftUI

struct AlertSummaryView: View {
    let alerts: [Alert]
    @Binding var selectedTab: SidebarView.SidebarTab
    var maxDisplay: Int = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Alerts")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    selectedTab = .alerts
                }
                .buttonStyle(.link)
                .accessibilityHint("Navigate to alerts view")
            }

            if alerts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("No alerts")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(alerts.prefix(maxDisplay)) { alert in
                            AlertSummaryRowView(alert: alert)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct AlertSummaryRowView: View {
    let alert: Alert

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.severity.icon)
                .foregroundColor(alert.severity.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(alert.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
