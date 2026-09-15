import Foundation

enum ValveStatus: String, Codable, CaseIterable, Identifiable {
    case open = "Open"
    case closed = "Closed"
    case partiallyOpen = "Partially Open"
    case locked = "Locked"
    case fault = "Fault"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .open: return "lock.open.fill"
        case .closed: return "lock.fill"
        case .partiallyOpen: return "lock.rotation"
        case .locked: return "lock.fill"
        case .fault: return "exclamationmark.lock.fill"
        }
    }
}
