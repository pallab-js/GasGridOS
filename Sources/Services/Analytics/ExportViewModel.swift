import Foundation
import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.gasgrid", category: "Export")

@MainActor
final class ExportViewModel: ObservableObject {
    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0
    @Published var exportComplete: Bool = false
    @Published var exportedFilePath: String?
    @Published var previewData: [String] = []
    @Published var previewCount: Int = 0

    private let stationRepo = StationRepository()
    private let pipelineRepo = PipelineRepository()
    private let alertRepo = AlertRepository()

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case pdf = "PDF"
    }

    enum ExportType: String, CaseIterable {
        case stations = "Stations"
        case pipelines = "Pipelines"
        case alerts = "Alerts"
        case all = "All Data"
    }

    init() {
        loadPreview()
    }

    func loadPreview() {
        do {
            let stations = try stationRepo.fetchAll()
            let pipelines = try pipelineRepo.fetchAll()
            let alerts = try alertRepo.fetchAll()

            var data: [String] = []
            var count = 0

            if !stations.isEmpty {
                data.append("=== STATIONS (\(stations.count)) ===")
                for station in stations.prefix(3) {
                    data.append("  \(station.name) - \(station.status.rawValue) - \(String(format: "%.2f bar", station.pressure))")
                }
                count += stations.count
            }

            if !pipelines.isEmpty {
                data.append("=== PIPELINES (\(pipelines.count)) ===")
                for pipeline in pipelines.prefix(3) {
                    data.append("  \(pipeline.name) - \(pipeline.material.rawValue) - \(String(format: "%.1f km", pipeline.length))")
                }
                count += pipelines.count
            }

            if !alerts.isEmpty {
                data.append("=== ALERTS (\(alerts.count)) ===")
                for alert in alerts.prefix(3) {
                    data.append("  \(alert.title) - \(alert.severity.rawValue)")
                }
                count += alerts.count
            }

            previewData = data
            previewCount = count
        } catch {
            previewData = ["Error loading preview data"]
        }
    }

    func exportData(format: ExportFormat, type: ExportType) async {
        isExporting = true
        exportProgress = 0
        exportComplete = false

        do {
            let fileManager = FileManager.default
            guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw NSError(domain: "ExportViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access Documents directory"])
            }
            let exportFolder = documentsPath.appendingPathComponent("GasGridManager Exports")

            try fileManager.createDirectory(at: exportFolder, withIntermediateDirectories: true)

            let timestamp = DateFormatter.exportDateFormatter.string(from: Date())
            let fileName = "GasGrid_\(type.rawValue)_\(timestamp).\(format.rawValue.lowercased())"
            let fileURL = exportFolder.appendingPathComponent(fileName)

            exportProgress = 0.3

            let data: Data

            switch type {
            case .stations:
                let stations = try stationRepo.fetchAll()
                data = formatStations(stations, format: format)
            case .pipelines:
                let pipelines = try pipelineRepo.fetchAll()
                data = formatPipelines(pipelines, format: format)
            case .alerts:
                let alerts = try alertRepo.fetchAll()
                data = formatAlerts(alerts, format: format)
            case .all:
                let stations = try stationRepo.fetchAll()
                let pipelines = try pipelineRepo.fetchAll()
                let alerts = try alertRepo.fetchAll()
                data = formatAllData(stations: stations, pipelines: pipelines, alerts: alerts, format: format)
            }

            exportProgress = 0.7

            try data.write(to: fileURL)

            exportProgress = 1.0
            exportedFilePath = fileURL.path
            exportComplete = true

        } catch {
            logger.error("Export failed: \(error.localizedDescription)")
        }

        isExporting = false
    }

    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    private func formatStations(_ stations: [NetworkStation], format: ExportFormat) -> Data {
        switch format {
        case .csv:
            var csv = "Name,Type,Status,Pressure (bar),Flow Rate (m³/h),Temperature (°C)\n"
            for station in stations {
                csv += "\(escapeCSV(station.name)),\(escapeCSV(station.stationType.rawValue)),\(escapeCSV(station.status.rawValue)),\(station.pressure),\(station.flowRate),\(station.temperature)\n"
            }
            return csv.data(using: .utf8) ?? Data()
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return (try? encoder.encode(stations)) ?? Data()
        case .pdf:
            return generatePDF(title: "Stations Report", items: stations.map { $0.name })
        }
    }

    private func formatPipelines(_ pipelines: [Pipeline], format: ExportFormat) -> Data {
        switch format {
        case .csv:
            var csv = "Name,Material,Diameter (mm),Length (km),Pressure (bar)\n"
            for pipeline in pipelines {
                csv += "\(escapeCSV(pipeline.name)),\(escapeCSV(pipeline.material.rawValue)),\(pipeline.diameter),\(pipeline.length),\(pipeline.pressure)\n"
            }
            return csv.data(using: .utf8) ?? Data()
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return (try? encoder.encode(pipelines)) ?? Data()
        case .pdf:
            return generatePDF(title: "Pipelines Report", items: pipelines.map { $0.name })
        }
    }

    private func formatAlerts(_ alerts: [Alert], format: ExportFormat) -> Data {
        switch format {
        case .csv:
            var csv = "Title,Severity,Message,Timestamp,Acknowledged\n"
            for alert in alerts {
                csv += "\(escapeCSV(alert.title)),\(escapeCSV(alert.severity.rawValue)),\(escapeCSV(alert.message)),\(alert.timestamp),\(alert.isAcknowledged)\n"
            }
            return csv.data(using: .utf8) ?? Data()
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return (try? encoder.encode(alerts)) ?? Data()
        case .pdf:
            return generatePDF(title: "Alerts Report", items: alerts.map { $0.title })
        }
    }

    private func formatAllData(stations: [NetworkStation], pipelines: [Pipeline], alerts: [Alert], format: ExportFormat) -> Data {
        switch format {
        case .csv:
            var csv = "GasGrid Manager Export\n"
            csv += "Date: \(Date())\n\n"
            csv += "STATIONS\n"
            csv += "Name,Type,Status,Pressure\n"
            for station in stations {
                csv += "\(escapeCSV(station.name)),\(escapeCSV(station.stationType.rawValue)),\(escapeCSV(station.status.rawValue)),\(station.pressure)\n"
            }
            csv += "\nPIPELINES\n"
            csv += "Name,Material,Length\n"
            for pipeline in pipelines {
                csv += "\(escapeCSV(pipeline.name)),\(escapeCSV(pipeline.material.rawValue)),\(pipeline.length)\n"
            }
            csv += "\nALERTS\n"
            csv += "Title,Severity,Acknowledged\n"
            for alert in alerts {
                csv += "\(escapeCSV(alert.title)),\(escapeCSV(alert.severity.rawValue)),\(alert.isAcknowledged)\n"
            }
            return csv.data(using: .utf8) ?? Data()
        case .json:
            var data: [String: Any] = [:]
            data["exportDate"] = ISO8601DateFormatter().string(from: Date())
            data["stations"] = stations.map { ["name": $0.name, "status": $0.status.rawValue] }
            data["pipelines"] = pipelines.map { ["name": $0.name, "material": $0.material.rawValue] }
            data["alerts"] = alerts.map { ["title": $0.title, "severity": $0.severity.rawValue] }
            return (try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)) ?? Data()
        case .pdf:
            return generatePDF(title: "Complete Export", items: ["\(stations.count) stations", "\(pipelines.count) pipelines", "\(alerts.count) alerts"])
        }
    }

    private func generatePDF(title: String, items: [String]) -> Data {
        let content = "\(title)\n\nGenerated: \(Date())\n\nItems:\n\(items.map { "• \($0)" }.joined(separator: "\n"))"
        return content.data(using: .utf8) ?? Data()
    }
}

extension DateFormatter {
    static let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
