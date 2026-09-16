import SwiftUI

struct AlertDetailView: View {
    let alert: Alert
    @Environment(\.dismiss) var dismiss
    @State private var notes: String
    @State private var isAcknowledging = false

    let onAcknowledge: (String?) -> Void

    init(alert: Alert, onAcknowledge: @escaping (String?) -> Void) {
        self.alert = alert
        self.onAcknowledge = onAcknowledge
        _notes = State(initialValue: alert.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection

            Divider()

            alertInfoSection

            Divider()

            notesSection

            Divider()

            actionButtons
        }
        .padding()
        .frame(width: 550, height: 500)
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: alert.severity.icon)
                .font(.system(size: 40))
                .foregroundColor(alert.severity.color)

            VStack(alignment: .leading) {
                Text(alert.title)
                    .font(.title2)
                    .fontWeight(.bold)

                StatusBadge(
                    text: alert.severity.rawValue,
                    color: alert.severity.color,
                    icon: alert.severity.icon
                )
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    private var alertInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailInfoRow(label: "Message", value: alert.message)
            DetailInfoRow(label: "Timestamp", value: alert.timestamp.formatted(date: .long, time: .standard))
            DetailInfoRow(label: "Status", value: alert.isAcknowledged ? "Acknowledged" : "Active")

            if let acknowledgedDate = alert.acknowledgedDate {
                DetailInfoRow(label: "Acknowledged At", value: acknowledgedDate.formatted(date: .long, time: .standard))
            }

            if let stationId = alert.stationId {
                DetailInfoRow(label: "Station ID", value: stationId.uuidString.prefix(8).uppercased() + "...")
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notes")
                    .font(.headline)
                Spacer()
                if !notes.isEmpty {
                    Button("Clear") { notes = "" }
                        .font(.caption)
                }
            }

            TextEditor(text: $notes)
                .font(.body)
                .frame(height: 100)
                .padding(4)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var actionButtons: some View {
        HStack {
            if alert.isAcknowledged {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("This alert was acknowledged")
                        .foregroundColor(.secondary)
                }
            } else {
                Button(action: {
                    isAcknowledging = true
                    onAcknowledge(notes.isEmpty ? nil : notes)
                    dismiss()
                }) {
                    if isAcknowledging {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Acknowledge Alert", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAcknowledging)
            }

            Spacer()

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
    }
}

struct DetailInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.subheadline)
        }
    }
}
