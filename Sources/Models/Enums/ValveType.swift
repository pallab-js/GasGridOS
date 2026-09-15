import Foundation

enum ValveType: String, Codable, CaseIterable, Identifiable {
    case gate = "Gate Valve"
    case globe = "Globe Valve"
    case ball = "Ball Valve"
    case butterfly = "Butterfly Valve"
    case check = "Check Valve"
    case pressureRelief = "Pressure Relief Valve"
    case emergencyShutdown = "Emergency Shutdown Valve"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gate: return "rectangle.portrait"
        case .globe: return "circle"
        case .ball: return "circle.fill"
        case .butterfly: return "butterfly"
        case .check: return "arrow.right.circle"
        case .pressureRelief: return "exclamationmark.shield"
        case .emergencyShutdown: return "xmark.shield.fill"
        }
    }
}
