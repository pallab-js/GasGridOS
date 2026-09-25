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
    @Published var errorMessage: String?

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
            previewCount = 0
        }
    }

    func exportData(format: ExportFormat, type: ExportType) async {
        isExporting = true
        exportProgress = 0
        exportComplete = false
        errorMessage = nil

        do {
            let fileManager = FileManager.default
            guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw NSError(domain: "ExportViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access Documents directory"])
            }
            let exportFolder = documentsPath.appendingPathComponent("GasGridManager Exports")

            try fileManager.createDirectory(at: exportFolder, withIntermediateDirectories: true)

            let timestamp = DateFormatter.exportDateFormatter.string(from: Date())
            let fileExtension = format == .csv ? "csv" : format.rawValue.lowercased()
            let fileName = "GasGrid_\(type.rawValue)_\(timestamp).\(fileExtension)"
            let fileURL = exportFolder.appendingPathComponent(fileName)

            exportProgress = 0.3

            let data: Data

            switch type {
            case .stations:
                data = try formatStations(try stationRepo.fetchAll(), format: format)
            case .pipelines:
                data = try formatPipelines(try pipelineRepo.fetchAll(), format: format)
            case .alerts:
                data = try formatAlerts(try alertRepo.fetchAll(), format: format)
            case .all:
                data = try formatAllData(
                    stations: try stationRepo.fetchAll(),
                    pipelines: try pipelineRepo.fetchAll(),
                    alerts: try alertRepo.fetchAll(),
                    format: format
                )
            }

            exportProgress = 0.7

            try data.write(to: fileURL, options: .atomic)

            exportProgress = 1.0
            exportedFilePath = fileURL.path
            exportComplete = true
            loadPreview()

        } catch {
            logger.error("Export failed: \(error.localizedDescription)")
            errorMessage = "Export failed: \(error.localizedDescription)"
            exportedFilePath = nil
        }

        isExporting = false
    }

    /// RFC 4180 quoting plus protection against spreadsheet formula injection.
    private func escapeCSV(_ field: String) -> String {
        let formulaStarters: Set<Character> = ["=", "+", "-", "@", "\t", "\r"]
        var value = field
        if let first = field.first, formulaStarters.contains(first) {
            value = "'\(field)"
        }

        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    /// UTF-8 with BOM so spreadsheet apps detect `m³` / `°C` correctly.
    private func csvData(_ csv: String) -> Data {
        Data(("\u{FEFF}" + csv).utf8)
    }

    private func isoString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func formatStations(_ stations: [NetworkStation], format: ExportFormat) throws -> Data {
        switch format {
        case .csv:
            var csv = "Name,Type,Status,Pressure (bar),Flow Rate (m³/h),Temperature (°C)\n"
            for station in stations {
                csv += "\(escapeCSV(station.name)),\(escapeCSV(station.stationType.rawValue)),\(escapeCSV(station.status.rawValue)),\(station.pressure),\(station.flowRate),\(station.temperature)\n"
            }
            return csvData(csv)
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(stations)
        case .pdf:
            return PDFWriter.makePDF(
                title: "Stations Report",
                subtitle: "Generated \(isoString(Date()))",
                bodyLines: stations.map {
                    "\($0.name) | \($0.stationType.rawValue) | \($0.status.rawValue) | \(String(format: "%.2f bar", $0.pressure))"
                }
            )
        }
    }

    private func formatPipelines(_ pipelines: [Pipeline], format: ExportFormat) throws -> Data {
        switch format {
        case .csv:
            var csv = "Name,Material,Diameter (mm),Length (km),Pressure (bar)\n"
            for pipeline in pipelines {
                csv += "\(escapeCSV(pipeline.name)),\(escapeCSV(pipeline.material.rawValue)),\(pipeline.diameter),\(pipeline.length),\(pipeline.pressure)\n"
            }
            return csvData(csv)
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(pipelines)
        case .pdf:
            return PDFWriter.makePDF(
                title: "Pipelines Report",
                subtitle: "Generated \(isoString(Date()))",
                bodyLines: pipelines.map {
                    "\($0.name) | \($0.material.rawValue) | \(String(format: "%.1f km", $0.length))"
                }
            )
        }
    }

    private func formatAlerts(_ alerts: [Alert], format: ExportFormat) throws -> Data {
        switch format {
        case .csv:
            var csv = "Title,Severity,Message,Timestamp,Acknowledged\n"
            for alert in alerts {
                csv += "\(escapeCSV(alert.title)),\(escapeCSV(alert.severity.rawValue)),\(escapeCSV(alert.message)),\(isoString(alert.timestamp)),\(alert.isAcknowledged)\n"
            }
            return csvData(csv)
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(alerts)
        case .pdf:
            return PDFWriter.makePDF(
                title: "Alerts Report",
                subtitle: "Generated \(isoString(Date()))",
                bodyLines: alerts.map {
                    "[\($0.severity.rawValue)] \(isoString($0.timestamp)) - \($0.title)"
                }
            )
        }
    }

    private func formatAllData(stations: [NetworkStation], pipelines: [Pipeline], alerts: [Alert], format: ExportFormat) throws -> Data {
        switch format {
        case .csv:
            var csv = "STATIONS\n"
            csv += "Name,Type,Status,Pressure,Flow Rate,Temperature\n"
            for station in stations {
                csv += "\(escapeCSV(station.name)),\(escapeCSV(station.stationType.rawValue)),\(escapeCSV(station.status.rawValue)),\(station.pressure),\(station.flowRate),\(station.temperature)\n"
            }
            csv += "\nPIPELINES\n"
            csv += "Name,Material,Diameter,Length,Pressure\n"
            for pipeline in pipelines {
                csv += "\(escapeCSV(pipeline.name)),\(escapeCSV(pipeline.material.rawValue)),\(pipeline.diameter),\(pipeline.length),\(pipeline.pressure)\n"
            }
            csv += "\nALERTS\n"
            csv += "Title,Severity,Message,Timestamp,Acknowledged\n"
            for alert in alerts {
                csv += "\(escapeCSV(alert.title)),\(escapeCSV(alert.severity.rawValue)),\(escapeCSV(alert.message)),\(isoString(alert.timestamp)),\(alert.isAcknowledged)\n"
            }
            return csvData(csv)
        case .json:
            var data: [String: Any] = [:]
            data["exportDate"] = ISO8601DateFormatter().string(from: Date())
            data["stations"] = stations.map { ["name": $0.name, "status": $0.status.rawValue] }
            data["pipelines"] = pipelines.map { ["name": $0.name, "material": $0.material.rawValue] }
            data["alerts"] = alerts.map { ["title": $0.title, "severity": $0.severity.rawValue] }
            return try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        case .pdf:
            var lines = ["Stations: \(stations.count)", "Pipelines: \(pipelines.count)", "Alerts: \(alerts.count)", ""]
            lines += stations.map { "  Station: \($0.name) (\($0.status.rawValue))" }
            lines += pipelines.map { "  Pipeline: \($0.name) (\($0.material.rawValue))" }
            lines += alerts.map { "  Alert: \($0.title) [\($0.severity.rawValue)]" }
            return PDFWriter.makePDF(
                title: "Complete Export",
                subtitle: "Generated \(isoString(Date()))",
                bodyLines: lines
            )
        }
    }
}

extension DateFormatter {
    static let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
        return formatter
    }()
}
