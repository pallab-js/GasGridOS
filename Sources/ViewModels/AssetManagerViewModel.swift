import Foundation
import SwiftUI

@MainActor
final class AssetManagerViewModel: ObservableObject {
    @Published var stations: [NetworkStation] = []
    @Published var pipelines: [Pipeline] = []
    @Published var sensors: [Sensor] = []
    @Published var valves: [Valve] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: AssetFilter = .all
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let stationRepo = StationRepository()
    private let pipelineRepo = PipelineRepository()
    private let sensorRepo = SensorRepository()
    private let valveRepo = ValveRepository()

    enum AssetFilter: String, CaseIterable {
        case all = "All"
        case stations = "Stations"
        case pipelines = "Pipelines"
        case sensors = "Sensors"
        case valves = "Valves"
    }

    var filteredStations: [NetworkStation] {
        if searchText.isEmpty {
            return stations
        }
        return stations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredPipelines: [Pipeline] {
        if searchText.isEmpty {
            return pipelines
        }
        return pipelines.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func loadData() async {
        isLoading = true

        do {
            stations = try stationRepo.fetchAll()
            pipelines = try pipelineRepo.fetchAll()
            sensors = try sensorRepo.fetchAll()
            valves = try valveRepo.fetchAll()
        } catch {
            errorMessage = "Failed to load asset data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func deleteStation(_ station: NetworkStation) throws {
        try stationRepo.delete(station)
        stations.removeAll { $0.id == station.id }
    }

    func deletePipeline(_ pipeline: Pipeline) throws {
        try pipelineRepo.delete(pipeline)
        pipelines.removeAll { $0.id == pipeline.id }
    }
}
