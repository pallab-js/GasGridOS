import Foundation

@MainActor
final class ValveViewModel: ObservableObject {
    @Published var valves: [Valve] = []
    @Published var stations: [NetworkStation] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let valveRepo = ValveRepository()
    private let stationRepo = StationRepository()

    var filteredValves: [Valve] {
        if searchText.isEmpty {
            return valves
        }
        return valves.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func loadData() async {
        isLoading = true
        do {
            valves = try valveRepo.fetchAll()
            stations = try stationRepo.fetchAll()
        } catch {
            errorMessage = "Failed to load valves: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func addValve(_ valve: Valve) {
        do {
            try valveRepo.insert(valve)
            valves.append(valve)
        } catch {
            errorMessage = "Failed to add valve: \(error.localizedDescription)"
        }
    }

    func updateValve(_ valve: Valve) {
        do {
            try valveRepo.update(valve)
            if let index = valves.firstIndex(where: { $0.id == valve.id }) {
                valves[index] = valve
            }
        } catch {
            errorMessage = "Failed to update valve: \(error.localizedDescription)"
        }
    }

    func deleteValve(_ valve: Valve) {
        do {
            try valveRepo.delete(valve)
            valves.removeAll { $0.id == valve.id }
            DatabaseManager.shared.logAuditEvent("DELETE_VALVE", details: "Deleted valve '\(valve.name)' (ID: \(valve.id.uuidString))")
        } catch {
            errorMessage = "Failed to delete valve: \(error.localizedDescription)"
        }
    }
}
