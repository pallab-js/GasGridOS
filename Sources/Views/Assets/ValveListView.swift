import SwiftUI

struct ValveListView: View {
    @StateObject private var viewModel = ValveViewModel()
    @State private var showingAddValve = false
    @State private var selectedValve: Valve?
    @State private var valveToDelete: Valve?

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            if viewModel.isLoading {
                ProgressView("Loading valves...")
                    .frame(maxHeight: .infinity)
            } else if viewModel.valves.isEmpty {
                emptyStateView
            } else {
                valveList
            }
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showingAddValve) {
            AddValveSheet(stations: viewModel.stations) { valve in
                viewModel.addValve(valve)
            }
        }
        .sheet(item: $selectedValve) { valve in
            ValveDetailView(valve: valve) { updatedValve in
                viewModel.updateValve(updatedValve)
            }
        }
        .alert("Delete Valve", isPresented: Binding(
            get: { valveToDelete != nil },
            set: { if !$0 { valveToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { valveToDelete = nil }
            Button("Delete", role: .destructive) {
                if let valve = valveToDelete {
                    viewModel.deleteValve(valve)
                }
                valveToDelete = nil
            }
        } message: {
            if let valve = valveToDelete {
                Text("Are you sure you want to delete \(valve.name)? This action cannot be undone.")
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
                Text("Valves")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(viewModel.valves.count) valves in network")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack {
                TextField("Search valves...", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)

                Button(action: { showingAddValve = true }) {
                    Label("Add Valve", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No valves found")
                .font(.title3)
            Text("Add valves to manage flow control in your network")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Add First Valve") {
                showingAddValve = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }

    private var valveList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                let lastId = viewModel.filteredValves.last?.id
                ForEach(viewModel.filteredValves) { valve in
                    Button(action: { selectedValve = valve }) {
                        ValveRowView(valve: valve, onDelete: {
                            valveToDelete = valve
                        })
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View \(valve.name) details")
                    if valve.id != lastId {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct ValveRowView: View {
    let valve: Valve
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: valve.valveType.icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(valve.name)
                    .fontWeight(.medium)
                Text(valve.valveType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            StatusBadge(
                text: valve.status.rawValue,
                color: valve.status.color,
                icon: valve.status.icon
            )

            VStack(alignment: .trailing) {
                Text(String(format: "%.0f%%", valve.position * 100))
                    .font(.caption)
                Text(String(format: "%.0f mm", valve.diameter))
                    .font(.caption)
                    .foregroundColor(.secondary)
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
            .frame(width: 24)
            .accessibilityLabel("More actions")

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct ValveDetailView: View {
    @Environment(\.dismiss) var dismiss
    let valve: Valve
    let onSave: (Valve) -> Void

    @State private var name: String
    @State private var status: ValveStatus
    @State private var position: Double
    @State private var notes: String

    init(valve: Valve, onSave: @escaping (Valve) -> Void) {
        self.valve = valve
        self.onSave = onSave
        _name = State(initialValue: valve.name)
        _status = State(initialValue: valve.status)
        _position = State(initialValue: valve.position)
        _notes = State(initialValue: valve.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Valve Details")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(valve.valveType.rawValue)
                        .foregroundColor(.secondary)
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

            Divider()

            Form {
                Section("General") {
                    TextField("Name", text: $name)

                    Picker("Status", selection: $status) {
                        ForEach(ValveStatus.allCases) { status in
                            Label(status.rawValue, systemImage: status.icon).tag(status)
                        }
                    }
                }

                Section("Position") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Position")
                            Spacer()
                            Text(String(format: "%.0f%%", position * 100))
                                .fontWeight(.medium)
                        }
                        Slider(value: $position, in: 0...1, step: 0.01)
                    }
                }

                Section("Details") {
                    HStack {
                        Text("Diameter")
                        Spacer()
                        Text(String(format: "%.0f mm", valve.diameter))
                            .foregroundColor(.secondary)
                    }

                    if let lastMaintenance = valve.lastMaintenanceDate {
                        HStack {
                            Text("Last Maintenance")
                            Spacer()
                            Text(lastMaintenance.formatted(date: .abbreviated, time: .omitted))
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
                    var updated = valve
                    updated.name = name
                    updated.status = status
                    updated.position = position
                    updated.notes = notes.isEmpty ? nil : notes
                    onSave(updated)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }
}

struct AddValveSheet: View {
    @Environment(\.dismiss) var dismiss
    let stations: [NetworkStation]
    @State private var name = ""
    @State private var selectedStation: NetworkStation?
    @State private var valveType: ValveType = .gate
    @State private var diameter: Double = 100

    let onSave: (Valve) -> Void

    private var isValid: Bool {
        !name.isEmpty && selectedStation != nil && diameter > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add New Valve")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                TextField("Valve Name", text: $name)

                Picker("Station", selection: $selectedStation) {
                    Text("Select...").tag(nil as NetworkStation?)
                    ForEach(stations) { station in
                        Text(station.name).tag(station as NetworkStation?)
                    }
                }

                Picker("Valve Type", selection: $valveType) {
                    ForEach(ValveType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }

                HStack {
                    Text("Diameter (mm)")
                    Spacer()
                    TextField("Diameter", value: $diameter, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                if diameter <= 0 {
                    Text("Diameter must be greater than 0")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)

                Button("Add Valve") {
                    guard let station = selectedStation else { return }
                    let valve = Valve(
                        name: name,
                        stationId: station.id,
                        valveType: valveType,
                        diameter: diameter
                    )
                    onSave(valve)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 450, height: 480)
    }
}
