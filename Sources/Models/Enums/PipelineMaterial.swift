import Foundation

enum PipelineMaterial: String, Codable, CaseIterable, Identifiable {
    case steel = "Steel"
    case polyethylene = "Polyethylene (PE)"
    case pvc = "PVC"
    case copper = "Copper"
    case castIron = "Cast Iron"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .steel: return "High-pressure transmission lines"
        case .polyethylene: return "Medium-pressure distribution lines"
        case .pvc: return "Low-pressure service lines"
        case .copper: return "Service connections"
        case .castIron: return "Legacy infrastructure"
        }
    }
}
