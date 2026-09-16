import SwiftUI

struct AlertListView: View {
    @StateObject private var viewModel = AlertViewModel()
    @State private var selectedAlert: Alert?
    @State private var showingDetail = false
    @State private var alertToDelete: Alert?

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            filterSection

            Divider()

            if viewModel.isLoading {
                ProgressView("Loading alerts...")
                    .frame(maxHeight: .infinity)
            } else if viewModel.filteredAlerts.isEmpty {
                emptyStateView
            } else {
                alertList
            }
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(item: $selectedAlert) { alert in
            AlertDetailView(alert: alert) { notes in
                viewModel.acknowledgeAlert(alert, notes: notes)
            }
        }
        .alert("Delete Alert", isPresented: Binding(
            get: { alertToDelete != nil },
            set: { if !$0 { alertToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { alertToDelete = nil }
            Button("Delete", role: .destructive) {
                if let alert = alertToDelete {
                    viewModel.deleteAlert(alert)
                }
                alertToDelete = nil
            }
        } message: {
            if let alert = alertToDelete {
                Text("Are you sure you want to delete '\(alert.title)'?")
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Alerts")
                    .font(.title2)
                    .fontWeight(.bold)
                HStack(spacing: 8) {
                    Text("\(viewModel.unacknowledgedCount) unacknowledged")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if viewModel.criticalCount > 0 {
                        Text("•")
                        Text("\(viewModel.criticalCount) critical")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            Spacer()

            Toggle("Unacknowledged Only", isOn: $viewModel.showUnacknowledgedOnly)
                .toggleStyle(.switch)
        }
        .padding()
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: viewModel.selectedSeverity == nil,
                    color: .gray
                ) {
                    viewModel.selectedSeverity = nil
                }

                ForEach(AlertSeverity.allCases) { severity in
                    FilterChip(
                        title: severity.rawValue,
                        isSelected: viewModel.selectedSeverity == severity,
                        color: severity.color
                    ) {
                        viewModel.selectedSeverity = severity
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            Text("No alerts")
                .font(.title3)
            Text("All systems operating normally")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private var alertList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredAlerts) { alert in
                    AlertRowView(
                        alert: alert,
                        onAcknowledge: { viewModel.acknowledgeAlert(alert) },
                        onDelete: { alertToDelete = alert }
                    )
                    .onTapGesture { selectedAlert = alert }
                    if alert.id != viewModel.filteredAlerts.last?.id {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? color : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? color : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AlertRowView: View {
    let alert: Alert
    let onAcknowledge: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: alert.severity.icon)
                .font(.title3)
                .foregroundColor(alert.severity.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title)
                        .font(.headline)
                    if alert.isAcknowledged {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                Text(alert.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Text(alert.timestamp, style: .relative)
                    Text("ago")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                if !alert.isAcknowledged {
                    Button(action: onAcknowledge) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Menu {
                    Button(action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(alert.severity == .critical ? Color.red.opacity(0.05) : Color.clear)
        .opacity(alert.isAcknowledged ? 0.6 : 1)
    }
}
