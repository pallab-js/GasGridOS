import Foundation

enum StationType: String, Codable, CaseIterable, Identifiable {
    case gasMeteringStation = "Gas Metering Station"
    case pressureRegulatingStation = "Pressure Regulating Station"
    case districtMeteringArea = "District Metering Area"
    case compressorStation = "Compressor Station"
    case storageFacility = "Storage Facility"
    case distributionNode = "Distribution Node"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gasMeteringStation: return "gauge.medium"
        case .pressureRegulatingStation: return "arrow.triangle.2.circlepath"
        case .districtMeteringArea: return "map.circle"
        case .compressorStation: return "fan"
        case .storageFacility: return "cylinder"
        case .distributionNode: return "point.3.connected.trianglepath.dotted"
        }
    }
}
