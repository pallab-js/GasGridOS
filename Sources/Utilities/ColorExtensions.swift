import SwiftUI

extension AlertSeverity {
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case .info: return .gray
        }
    }
}

extension ValveStatus {
    var color: Color {
        switch self {
        case .open: return .green
        case .closed: return .red
        case .partiallyOpen: return .orange
        case .locked: return .purple
        case .fault: return .red
        }
    }
}

extension StationStatus {
    var color: Color {
        switch self {
        case .online: return .green
        case .offline: return .gray
        case .maintenance: return .orange
        case .critical: return .red
        case .warning: return .yellow
        }
    }
}
