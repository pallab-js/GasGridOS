import Foundation
import SwiftUI

@MainActor
final class NetworkMapViewModel: ObservableObject {
    @Published var stations: [NetworkStation] = []
    @Published var pipelines: [Pipeline] = []
    @Published var selectedStation: NetworkStation?
    @Published var isLoading: Bool = false
    @Published var stationPositions: [UUID: CGPoint] = [:]
    @Published var errorMessage: String?

    private let stationRepo = StationRepository()
    private let pipelineRepo = PipelineRepository()

    func loadData() async {
        isLoading = true

        do {
            stations = try stationRepo.fetchAll()
            pipelines = try pipelineRepo.fetchAll()
            computePositions()
        } catch {
            errorMessage = "Failed to load network data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func selectStation(_ station: NetworkStation) {
        selectedStation = station
    }

    func deselectStation() {
        selectedStation = nil
    }

    func addStation(_ station: NetworkStation) throws {
        try stationRepo.insert(station)
        stations.append(station)
        computePositions()
    }

    private func computePositions() {
        guard !stations.isEmpty else {
            stationPositions = [:]
            return
        }

        let lats = stations.map(\.latitude)
        let lons = stations.map(\.longitude)

        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max() else { return }

        let latRange = maxLat - minLat
        let lonRange = maxLon - minLon

        let canvasWidth: CGFloat = 800
        let canvasHeight: CGFloat = 600
        let padding: CGFloat = 60

        let usableWidth = canvasWidth - padding * 2
        let usableHeight = canvasHeight - padding * 2

        var positions: [UUID: CGPoint] = [:]

        for station in stations {
            let x: CGFloat
            let y: CGFloat

            if lonRange > 0.001 {
                x = padding + CGFloat((station.longitude - minLon) / lonRange) * usableWidth
            } else {
                x = canvasWidth / 2
            }

            if latRange > 0.001 {
                y = padding + CGFloat((maxLat - station.latitude) / latRange) * usableHeight
            } else {
                y = canvasHeight / 2
            }

            positions[station.id] = CGPoint(x: x, y: y)
        }

        stationPositions = positions
    }
}
