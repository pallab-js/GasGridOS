import Foundation

enum StationStatus: String, Codable, CaseIterable, Identifiable {
    case online = "Online"
    case offline = "Offline"
    case maintenance = "Maintenance"
    case critical = "Critical"
    case warning = "Warning"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .online: return "checkmark.circle.fill"
        case .offline: return "xmark.circle.fill"
        case .maintenance: return "wrench.fill"
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        }
    }
}
