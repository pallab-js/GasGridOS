import Foundation

enum SensorType: String, Codable, CaseIterable, Identifiable {
    case pressure = "Pressure"
    case flowRate = "Flow Rate"
    case temperature = "Temperature"
    case gasDetection = "Gas Detection"
    case level = "Level"
    case vibration = "Vibration"

    var id: String { rawValue }

    var unit: String {
        switch self {
        case .pressure: return "bar"
        case .flowRate: return "m³/h"
        case .temperature: return "°C"
        case .gasDetection: return "ppm"
        case .level: return "%"
        case .vibration: return "mm/s"
        }
    }

    var icon: String {
        switch self {
        case .pressure: return "gauge.medium"
        case .flowRate: return "waveform.path.ecg"
        case .temperature: return "thermometer.medium"
        case .gasDetection: return "wind"
        case .level: return "drop.fill"
        case .vibration: return "waveform"
        }
    }
}
