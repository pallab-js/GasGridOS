import SwiftUI

struct NetworkMapView: View {
    @StateObject private var viewModel = NetworkMapViewModel()
    @State private var zoomLevel: CGFloat = 1.0
    @State private var showingAddStation = false

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            ZStack {
                Color(NSColor.textBackgroundColor)

                if viewModel.isLoading {
                    ProgressView("Loading network...")
                } else if viewModel.stations.isEmpty {
                    emptyStateView
                } else {
                    networkContent
                }
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
                Text("Network Map")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(viewModel.stations.count) stations • \(viewModel.pipelines.count) pipelines")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                zoomControls

                Divider()
                    .frame(height: 20)

                legendView

                Divider()
                    .frame(height: 20)

                Button(action: {
                    Task {
                        await viewModel.loadData()
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

                Button(action: { showingAddStation = true }) {
                    Label("Add Station", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var zoomControls: some View {
        HStack(spacing: 4) {
            Button(action: { withAnimation { zoomLevel = max(0.5, zoomLevel - 0.25) } }) {
                Image(systemName: "minus.magnifyingglass")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Zoom out")

            Text("\(Int(zoomLevel * 100))%")
                .font(.caption)
                .frame(width: 40)

            Button(action: { withAnimation { zoomLevel = min(3.0, zoomLevel + 0.25) } }) {
                Image(systemName: "plus.magnifyingglass")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Zoom in")

            Button(action: { withAnimation { zoomLevel = 1.0 } }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Reset zoom")
        }
    }

    private var legendView: some View {
        HStack(spacing: 12) {
            legendItem(color: .green, label: "Online")
            legendItem(color: .red, label: "Critical")
            legendItem(color: .orange, label: "Warning")
            legendItem(color: .gray, label: "Offline")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No network data available")
                .font(.title3)
            Text("Add stations and pipelines to visualize your network")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Add First Station") {
                showingAddStation = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var networkContent: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack {
                ForEach(viewModel.pipelines) { pipeline in
                    PipelineShapeView(pipeline: pipeline, stations: viewModel.stations, positions: viewModel.stationPositions)
                }

                ForEach(viewModel.stations) { station in
                    StationMarkerView(station: station, position: viewModel.stationPositions[station.id]) {
                        viewModel.selectStation(station)
                    }
                }
            }
            .frame(width: 800 * zoomLevel, height: 600 * zoomLevel)
        }
        .sheet(item: $viewModel.selectedStation) { station in
            StationDetailView(station: station)
        }
    }
}

struct StationMarkerView: View {
    let station: NetworkStation
    let position: CGPoint?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(station.status.color)
                        .frame(width: 28, height: 28)
                        .shadow(color: station.status.color.opacity(0.5), radius: 4)

                    Image(systemName: station.stationType.icon)
                        .font(.caption)
                        .foregroundColor(.white)
                }

                Text(station.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .buttonStyle(.plain)
        .position(x: position?.x ?? 0, y: position?.y ?? 0)
        .accessibilityLabel("\(station.name), \(station.status.rawValue)")
    }
}

struct PipelineShapeView: View {
    let pipeline: Pipeline
    let stations: [NetworkStation]
    let positions: [UUID: CGPoint]

    var body: some View {
        Path { path in
            guard let startStation = stations.first(where: { $0.id == pipeline.startStationId }),
                  let endStation = stations.first(where: { $0.id == pipeline.endStationId }),
                  let start = positions[startStation.id],
                  let end = positions[endStation.id] else { return }

            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(
            LinearGradient(
                colors: [.blue, .blue.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
    }
}

struct AddStationSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var stationType: StationType = .gasMeteringStation
    @State private var latitude: Double = 40.7128
    @State private var longitude: Double = -74.0060
    @State private var maximumPressure: Double = 5.0
    @State private var minimumPressure: Double = 3.0

    let onSave: (NetworkStation) -> Void

    private var isValid: Bool {
        !name.isEmpty &&
        latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180 &&
        minimumPressure >= 0 &&
        maximumPressure > minimumPressure
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add New Station")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                TextField("Station Name", text: $name)
                    .onChange(of: name) { _, newValue in
                        if newValue.count > 100 {
                            name = String(newValue.prefix(100))
                        }
                    }

                Picker("Station Type", selection: $stationType) {
                    ForEach(StationType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }

                Section("Location") {
                    HStack {
                        Text("Latitude")
                        Spacer()
                        TextField("Latitude", value: $latitude, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }
                    if latitude < -90 || latitude > 90 {
                        Text("Latitude must be between -90 and 90")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    HStack {
                        Text("Longitude")
                        Spacer()
                        TextField("Longitude", value: $longitude, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }
                    if longitude < -180 || longitude > 180 {
                        Text("Longitude must be between -180 and 180")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section("Pressure Limits") {
                    HStack {
                        Text("Min Pressure (bar)")
                        Spacer()
                        TextField("Min", value: $minimumPressure, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Max Pressure (bar)")
                        Spacer()
                        TextField("Max", value: $maximumPressure, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    if maximumPressure <= minimumPressure {
                        Text("Max pressure must be greater than min pressure")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)

                Button("Add Station") {
                    let station = NetworkStation(
                        name: name,
                        stationType: stationType,
                        latitude: latitude,
                        longitude: longitude,
                        maximumPressure: maximumPressure,
                        minimumPressure: minimumPressure
                    )
                    onSave(station)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 500, height: 580)
    }
}
