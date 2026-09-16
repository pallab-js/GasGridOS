import SwiftUI

struct AssetListView: View {
    @StateObject private var viewModel = AssetManagerViewModel()
    @State private var showingAddStation = false
    @State private var showingAddPipeline = false
    @State private var selectedStation: NetworkStation?

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            filterSection

            Divider()

            if viewModel.isLoading {
                ProgressView("Loading assets...")
                    .frame(maxHeight: .infinity)
            } else if viewModel.filteredStations.isEmpty && viewModel.filteredPipelines.isEmpty && viewModel.sensors.isEmpty {
                emptyStateView
            } else {
                assetContent
            }
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showingAddStation) {
            AddStationSheet { station in
                do {
                    try viewModel.addStation(station)
                } catch {
                    viewModel.errorMessage = "Failed to add station: \(error.localizedDescription)"
                }
            }
        }
        .sheet(isPresented: $showingAddPipeline) {
            AddPipelineSheet(stations: viewModel.stations) { pipeline in
                do {
                    try viewModel.addPipeline(pipeline)
                } catch {
                    viewModel.errorMessage = "Failed to add pipeline: \(error.localizedDescription)"
                }
            }
        }
        .sheet(item: $selectedStation) { station in
            StationDetailView(station: station)
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
                Text("Assets")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(viewModel.stations.count) stations • \(viewModel.pipelines.count) pipelines • \(viewModel.sensors.count) sensors")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack {
                TextField("Search assets...", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)

                Menu {
                    Button(action: { showingAddStation = true }) {
                        Label("Add Station", systemImage: "building.2")
                    }
                    Button(action: { showingAddPipeline = true }) {
                        Label("Add Pipeline", systemImage: "cable.connector")
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var filterSection: some View {
        Picker("Filter", selection: $viewModel.selectedFilter) {
            ForEach(AssetManagerViewModel.AssetFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No assets found")
                .font(.title3)
            Text("Add stations and pipelines to get started")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Add Station") {
                showingAddStation = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }

    private var assetContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.selectedFilter == .all || viewModel.selectedFilter == .stations {
                    assetSection(title: "Stations", count: viewModel.filteredStations.count) {
                        ForEach(viewModel.filteredStations) { station in
                            Button(action: { selectedStation = station }) {
                                StationRowView(station: station)
                            }
                            .buttonStyle(.plain)
                            if station.id != viewModel.filteredStations.last?.id {
                                Divider().padding(.leading, 48)
                            }
                        }
                    }
                }

                if viewModel.selectedFilter == .all || viewModel.selectedFilter == .pipelines {
                    assetSection(title: "Pipelines", count: viewModel.filteredPipelines.count) {
                        ForEach(viewModel.filteredPipelines) { pipeline in
                            PipelineRowView(pipeline: pipeline)
                            if pipeline.id != viewModel.filteredPipelines.last?.id {
                                Divider().padding(.leading, 48)
                            }
                        }
                    }
                }

                if viewModel.selectedFilter == .all || viewModel.selectedFilter == .sensors {
                    assetSection(title: "Sensors", count: viewModel.sensors.count) {
                        ForEach(viewModel.sensors) { sensor in
                            SensorRowView(sensor: sensor)
                            if sensor.id != viewModel.sensors.last?.id {
                                Divider().padding(.leading, 48)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func assetSection<Content: View>(title: String, count: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            content()
        }
    }
}

struct StationRowView: View {
    let station: NetworkStation

    var body: some View {
        HStack {
            Image(systemName: station.stationType.icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(station.name)
                    .fontWeight(.medium)
                Text(station.stationType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            StatusBadge(
                text: station.status.rawValue,
                color: station.status.color,
                icon: station.status.icon
            )

            VStack(alignment: .trailing) {
                Text(String(format: "%.2f bar", station.pressure))
                    .font(.caption)
                Text(String(format: "%.1f m³/h", station.flowRate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct PipelineRowView: View {
    let pipeline: Pipeline

    var body: some View {
        HStack {
            Image(systemName: "cable.connector")
                .foregroundColor(.green)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(pipeline.name)
                    .fontWeight(.medium)
                Text(pipeline.material.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(String(format: "%.1f km", pipeline.length))
                    .font(.caption)
                Text(String(format: "%.0f mm", pipeline.diameter))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct SensorRowView: View {
    let sensor: Sensor

    var body: some View {
        HStack {
            Image(systemName: sensor.sensorType.icon)
                .foregroundColor(.purple)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(sensor.name)
                    .fontWeight(.medium)
                Text(sensor.sensorType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            StatusBadge(
                text: sensor.isOnline ? "Online" : "Offline",
                color: sensor.isOnline ? .green : .red,
                icon: sensor.isOnline ? "checkmark.circle.fill" : "xmark.circle.fill"
            )

            VStack(alignment: .trailing) {
                if let reading = sensor.lastReading {
                    Text(String(format: "%.2f %@", reading, sensor.sensorType.unit))
                        .font(.caption)
                } else {
                    Text("No data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct AddPipelineSheet: View {
    @Environment(\.dismiss) var dismiss
    let stations: [NetworkStation]
    @State private var name = ""
    @State private var selectedStartStation: NetworkStation?
    @State private var selectedEndStation: NetworkStation?
    @State private var diameter: Double = 200
    @State private var material: PipelineMaterial = .steel
    @State private var length: Double = 10.0

    let onSave: (Pipeline) -> Void

    private var isValid: Bool {
        !name.isEmpty &&
        selectedStartStation != nil &&
        selectedEndStation != nil &&
        diameter > 0 &&
        length > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add New Pipeline")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                TextField("Pipeline Name", text: $name)

                Picker("Start Station", selection: $selectedStartStation) {
                    Text("Select...").tag(nil as NetworkStation?)
                    ForEach(stations) { station in
                        Text(station.name).tag(station as NetworkStation?)
                    }
                }

                Picker("End Station", selection: $selectedEndStation) {
                    Text("Select...").tag(nil as NetworkStation?)
                    ForEach(stations) { station in
                        Text(station.name).tag(station as NetworkStation?)
                    }
                }

                if selectedStartStation != nil && selectedEndStation != nil &&
                    selectedStartStation?.id == selectedEndStation?.id {
                    Text("Start and end stations must be different")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Picker("Material", selection: $material) {
                    ForEach(PipelineMaterial.allCases) { mat in
                        Text(mat.rawValue).tag(mat)
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

                HStack {
                    Text("Length (km)")
                    Spacer()
                    TextField("Length", value: $length, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                if length <= 0 {
                    Text("Length must be greater than 0")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)

                Button("Add Pipeline") {
                    guard let start = selectedStartStation, let end = selectedEndStation else { return }
                    let pipeline = Pipeline(
                        name: name,
                        startStationId: start.id,
                        endStationId: end.id,
                        startLatitude: start.latitude,
                        startLongitude: start.longitude,
                        endLatitude: end.latitude,
                        endLongitude: end.longitude,
                        diameter: diameter,
                        material: material,
                        length: length
                    )
                    onSave(pipeline)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 500, height: 530)
    }
}
