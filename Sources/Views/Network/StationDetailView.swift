import SwiftUI

struct StationDetailView: View {
    @Environment(\.dismiss) var dismiss
    let station: NetworkStation
    @State private var refreshedStation: NetworkStation?

    private var displayed: NetworkStation {
        refreshedStation ?? station
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection

            Divider()
                .padding(.top, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    metricsSection

                    Divider()

                    detailsSection
                }
                .padding(.top, 16)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 20)
        .frame(minWidth: 420, minHeight: 480)
        .task {
            await refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .gasGridRefreshData)) { _ in
            Task { await refresh() }
        }
    }

    private func refresh() async {
        do {
            refreshedStation = try StationRepository().fetchById(station.id)
        } catch {
            refreshedStation = nil
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayed.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(displayed.stationType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            StatusBadge(
                text: displayed.status.rawValue,
                color: displayed.status.color,
                icon: displayed.status.icon
            )
        }
        .padding(.top, 16)
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Metrics")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Pressure",
                    value: String(format: "%.2f bar", displayed.pressure),
                    icon: "gauge.medium",
                    color: displayed.isPressureNormal ? .blue : .red
                )

                MetricCard(
                    title: "Flow Rate",
                    value: String(format: "%.1f m³/h", displayed.flowRate),
                    icon: "waveform.path.ecg",
                    color: .green
                )

                MetricCard(
                    title: "Temperature",
                    value: String(format: "%.1f°C", displayed.temperature),
                    icon: "thermometer.medium",
                    color: .orange
                )

                MetricCard(
                    title: "Status",
                    value: displayed.status.rawValue,
                    icon: displayed.status.icon,
                    color: displayed.status.color
                )
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)

            DetailRow(label: "Installed", value: displayed.installedDate.formatted(date: .abbreviated, time: .omitted))
            DetailRow(label: "Last Maintenance", value: displayed.lastMaintenanceDate?.formatted(date: .abbreviated, time: .omitted) ?? "Never")
            DetailRow(label: "Min Pressure", value: String(format: "%.2f bar", displayed.minimumPressure))
            DetailRow(label: "Max Pressure", value: String(format: "%.2f bar", displayed.maximumPressure))

            if let notes = displayed.notes {
                DetailRow(label: "Notes", value: notes)
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .fontWeight(.medium)
                .lineLimit(3)
        }
        .font(.subheadline)
    }
}
