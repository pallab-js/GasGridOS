import Foundation

enum MaintenanceType: String, Codable, CaseIterable, Identifiable {
    case preventive = "Preventive"
    case corrective = "Corrective"
    case predictive = "Predictive"
    case emergency = "Emergency"
    case inspection = "Inspection"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .preventive: return "calendar.badge.checkmark"
        case .corrective: return "wrench.fill"
        case .predictive: return "brain.head.profile"
        case .emergency: return "exclamationmark.triangle.fill"
        case .inspection: return "magnifyingglass"
        }
    }
}
