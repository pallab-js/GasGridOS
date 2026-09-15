import SwiftUI

struct MaintenanceListView: View {
    @StateObject private var viewModel = MaintenanceViewModel()
    @State private var showingAddSheet = false
    @State private var selectedLog: MaintenanceLog?
    @State private var logToDelete: MaintenanceLog?

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            filterSection

            Divider()

            statsSection

            Divider()

            if viewModel.isLoading {
                ProgressView("Loading maintenance records...")
                    .frame(maxHeight: .infinity)
            } else if viewModel.filteredLogs.isEmpty {
                emptyStateView
            } else {
                maintenanceContent
            }
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddMaintenanceView { log in
                viewModel.addMaintenanceLog(log)
                showingAddSheet = false
            }
        }
        .sheet(item: $selectedLog) { log in
            MaintenanceDetailView(log: log) { updatedLog in
                viewModel.updateMaintenanceLog(updatedLog)
            }
        }
        .alert("Delete Task", isPresented: .constant(logToDelete != nil)) {
            Button("Cancel", role: .cancel) { logToDelete = nil }
            Button("Delete", role: .destructive) {
                if let log = logToDelete {
                    viewModel.deleteMaintenanceLog(log)
                }
                logToDelete = nil
            }
        } message: {
            if let log = logToDelete {
                Text("Delete '\(log.description)'?")
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Maintenance")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(viewModel.maintenanceLogs.count) scheduled tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { showingAddSheet = true }) {
                Label("Add Task", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var filterSection: some View {
        Picker("Filter", selection: $viewModel.selectedFilter) {
            ForEach(MaintenanceViewModel.MaintenanceFilter.allCases, id: \.self) { filter in
                HStack {
                    Text(filter.rawValue)
                    if filterCount(for: filter) > 0 {
                        Text("(\(filterCount(for: filter)))")
                            .foregroundColor(.secondary)
                    }
                }.tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func filterCount(for filter: MaintenanceViewModel.MaintenanceFilter) -> Int {
        switch filter {
        case .all: return viewModel.maintenanceLogs.count
        case .upcoming: return viewModel.upcomingMaintenance.count
        case .overdue: return viewModel.overdueMaintenance.count
        case .completed: return viewModel.completedMaintenance.count
        }
    }

    private var statsSection: some View {
        HStack(spacing: 16) {
            StatBadge(title: "Upcoming", count: viewModel.upcomingMaintenance.count, color: .blue)
            StatBadge(title: "Overdue", count: viewModel.overdueMaintenance.count, color: .red)
            StatBadge(title: "Completed", count: viewModel.completedMaintenance.count, color: .green)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No maintenance tasks")
                .font(.title3)
            Text("Add maintenance tasks to track scheduled work")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Add First Task") {
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }

    private var maintenanceContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredLogs) { log in
                    Button(action: { selectedLog = log }) {
                        MaintenanceRowView(log: log) {
                            viewModel.completeMaintenance(log)
                        } onDelete: {
                            logToDelete = log
                        }
                    }
                    .buttonStyle(.plain)
                    if log.id != viewModel.filteredLogs.last?.id {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct StatBadge: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct MaintenanceRowView: View {
    let log: MaintenanceLog
    let onComplete: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: log.maintenanceType.icon)
                .font(.title3)
                .foregroundColor(log.isOverdue ? .red : .blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.description)
                        .fontWeight(.medium)
                    if log.isOverdue {
                        Text("OVERDUE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red)
                            .clipShape(Capsule())
                    }
                }

                HStack {
                    Text(log.assetType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                    Text(log.maintenanceType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let performedBy = log.performedBy {
                    HStack(spacing: 4) {
                        Image(systemName: "person")
                            .font(.caption2)
                        Text(performedBy)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if log.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text(log.scheduledDate, style: .date)
                        .font(.caption)
                    Text(log.scheduledDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let cost = log.cost {
                    Text(String(format: "$%.2f", cost))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            HStack(spacing: 4) {
                if !log.isCompleted {
                    Button(action: onComplete) {
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
        .background(log.isOverdue ? Color.red.opacity(0.05) : Color.clear)
        .opacity(log.isCompleted ? 0.6 : 1)
    }
}

struct MaintenanceDetailView: View {
    @Environment(\.dismiss) var dismiss
    let log: MaintenanceLog
    let onSave: (MaintenanceLog) -> Void

    @State private var description: String
    @State private var maintenanceType: MaintenanceType
    @State private var scheduledDate: Date
    @State private var performedBy: String
    @State private var notes: String

    init(log: MaintenanceLog, onSave: @escaping (MaintenanceLog) -> Void) {
        self.log = log
        self.onSave = onSave
        _description = State(initialValue: log.description)
        _maintenanceType = State(initialValue: log.maintenanceType)
        _scheduledDate = State(initialValue: log.scheduledDate)
        _performedBy = State(initialValue: log.performedBy ?? "")
        _notes = State(initialValue: log.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Maintenance Task")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(log.assetType)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if log.isCompleted {
                    StatusBadge(text: "Completed", color: .green, icon: "checkmark.circle.fill")
                } else if log.isOverdue {
                    StatusBadge(text: "Overdue", color: .red, icon: "exclamationmark.circle.fill")
                }
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            Form {
                Section("Details") {
                    TextField("Description", text: $description)

                    Picker("Maintenance Type", selection: $maintenanceType) {
                        ForEach(MaintenanceType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }

                    DatePicker("Scheduled Date", selection: $scheduledDate)
                }

                Section("Assignment") {
                    TextField("Assigned To", text: $performedBy)

                    if let cost = log.cost {
                        HStack {
                            Text("Cost")
                            Spacer()
                            Text(String(format: "$%.2f", cost))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)

                Button("Save Changes") {
                    var updated = log
                    updated.description = description
                    updated.maintenanceType = maintenanceType
                    updated.scheduledDate = scheduledDate
                    updated.performedBy = performedBy.isEmpty ? nil : performedBy
                    updated.notes = notes.isEmpty ? nil : notes
                    onSave(updated)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(description.isEmpty)
            }
        }
        .padding()
        .frame(width: 550, height: 600)
    }
}

struct AddMaintenanceView: View {
    @Environment(\.dismiss) var dismiss
    @State private var description = ""
    @State private var assetType = "Station"
    @State private var maintenanceType: MaintenanceType = .preventive
    @State private var scheduledDate = Date()
    @State private var performedBy = ""

    let onSave: (MaintenanceLog) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Maintenance Task")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                TextField("Description", text: $description)

                Picker("Asset Type", selection: $assetType) {
                    Text("Station").tag("Station")
                    Text("Pipeline").tag("Pipeline")
                    Text("Valve").tag("Valve")
                    Text("Sensor").tag("Sensor")
                }

                Picker("Maintenance Type", selection: $maintenanceType) {
                    ForEach(MaintenanceType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }

                DatePicker("Scheduled Date", selection: $scheduledDate)

                TextField("Assigned To", text: $performedBy)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    let log = MaintenanceLog(
                        assetId: UUID(),
                        assetType: assetType,
                        maintenanceType: maintenanceType,
                        description: description,
                        scheduledDate: scheduledDate,
                        performedBy: performedBy.isEmpty ? nil : performedBy
                    )
                    onSave(log)
                }
                .buttonStyle(.borderedProminent)
                .disabled(description.isEmpty)
            }
        }
        .padding()
        .frame(width: 450, height: 500)
    }
}
