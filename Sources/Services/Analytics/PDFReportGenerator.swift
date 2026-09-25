import Foundation
import SwiftUI

@MainActor
final class PDFReportGenerator {
    static let shared = PDFReportGenerator()

    private init() {}

    func generateReport(type: ReportItem, reportType: ReportListView.ReportType, stations: [NetworkStation], pipelines: [Pipeline], alerts: [Alert]) -> Data {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        let dateString = formatter.string(from: Date())
        let windowStart = Date().addingTimeInterval(-reportType.window)
        let windowedAlerts = alerts.filter { $0.timestamp >= windowStart }

        var body = """
        \(reportType.rawValue) Report
        Generated: \(dateString)

        \(String(repeating: "=", count: 50))

        """

        switch type.title {
        case "Network Summary":
            body += generateNetworkSummary(stations: stations, pipelines: pipelines, alerts: windowedAlerts)
        case "Pressure Analysis":
            body += generatePressureAnalysis(stations: stations)
        case "Flow Report":
            body += generateFlowReport(stations: stations)
        case "Alert History":
            body += generateAlertHistory(alerts: windowedAlerts)
        case "Maintenance Log":
            body += generateMaintenanceLog()
        case "Asset Inventory":
            body += generateAssetInventory(stations: stations, pipelines: pipelines)
        case "Safety Report":
            body += generateSafetyReport(alerts: windowedAlerts)
        case "Cost Analysis":
            body += generateCostAnalysis()
        default:
            body += "Report data available upon request."
        }

        body += """

        \(String(repeating: "=", count: 50))
        End of Report
        """

        return PDFWriter.makePDF(
            title: "GasGrid Manager Report",
            subtitle: type.title,
            bodyLines: body.components(separatedBy: "\n")
        )
    }

    private func generateNetworkSummary(stations: [NetworkStation], pipelines: [Pipeline], alerts: [Alert]) -> String {
        let onlineStations = stations.filter { $0.status == .online }.count
        let totalLength = pipelines.reduce(0) { $0 + $1.length }
        let unackAlerts = alerts.filter { !$0.isAcknowledged }.count

        return """
        NETWORK SUMMARY

        Stations: \(stations.count) total (\(onlineStations) online)
        Pipelines: \(pipelines.count) total (\(String(format: "%.1f", totalLength)) km)
        Active Alerts: \(unackAlerts)

        Station Details:
        \(stations.map { "  - \($0.name): \($0.status.rawValue)" }.joined(separator: "\n"))

        """
    }

    private func generatePressureAnalysis(stations: [NetworkStation]) -> String {
        let pressures = stations.map { $0.pressure }
        let avgPressure = pressures.isEmpty ? 0 : pressures.reduce(0, +) / Double(pressures.count)
        let maxPressure = pressures.max() ?? 0
        let minPressure = pressures.min() ?? 0

        return """
        PRESSURE ANALYSIS

        Average Pressure: \(String(format: "%.2f", avgPressure)) bar
        Maximum Pressure: \(String(format: "%.2f", maxPressure)) bar
        Minimum Pressure: \(String(format: "%.2f", minPressure)) bar

        Station Pressures:
        \(stations.map { "  - \($0.name): \(String(format: "%.2f", $0.pressure)) bar" }.joined(separator: "\n"))

        """
    }

    private func generateFlowReport(stations: [NetworkStation]) -> String {
        let flows = stations.map { $0.flowRate }
        let totalFlow = flows.reduce(0, +)
        let avgFlow = flows.isEmpty ? 0 : totalFlow / Double(flows.count)

        return """
        FLOW REPORT

        Total Flow Rate: \(String(format: "%.1f", totalFlow)) m³/h
        Average Flow Rate: \(String(format: "%.1f", avgFlow)) m³/h per station

        Station Flows:
        \(stations.map { "  - \($0.name): \(String(format: "%.1f", $0.flowRate)) m³/h" }.joined(separator: "\n"))

        """
    }

    private func generateAlertHistory(alerts: [Alert]) -> String {
        let critical = alerts.filter { $0.severity == .critical }.count
        let high = alerts.filter { $0.severity == .high }.count
        let medium = alerts.filter { $0.severity == .medium }.count
        let low = alerts.filter { $0.severity == .low }.count

        return """
        ALERT HISTORY
        
        Total Alerts: \(alerts.count)
        Critical: \(critical)
        High: \(high)
        Medium: \(medium)
        Low: \(low)
        
        Recent Alerts:
        \(alerts.prefix(10).map { "  - [\($0.severity.rawValue)] \($0.title)" }.joined(separator: "\n"))
        
        """
    }

    private func generateMaintenanceLog() -> String {
        return """
        MAINTENANCE LOG
        
        Maintenance data is tracked in the Maintenance section.
        Please refer to the Maintenance view for detailed records.
        
        """
    }

    private func generateAssetInventory(stations: [NetworkStation], pipelines: [Pipeline]) -> String {
        return """
        ASSET INVENTORY
        
        Stations (\(stations.count)):
        \(stations.map { "  - \($0.name) (\($0.stationType.rawValue))" }.joined(separator: "\n"))
        
        Pipelines (\(pipelines.count)):
        \(pipelines.map { "  - \($0.name) (\($0.material.rawValue), \(String(format: "%.1f", $0.length)) km)" }.joined(separator: "\n"))
        
        """
    }

    private func generateSafetyReport(alerts: [Alert]) -> String {
        let criticalAlerts = alerts.filter { $0.severity == .critical }
        return """
        SAFETY REPORT
        
        Safety Status: \(criticalAlerts.isEmpty ? "NORMAL" : "ALERT")
        Critical Incidents: \(criticalAlerts.count)
        Total Alerts: \(alerts.count)
        
        \(criticalAlerts.isEmpty ? "No critical safety issues detected." : "Critical issues require immediate attention.")
        
        """
    }

    private func generateCostAnalysis() -> String {
        return """
        COST ANALYSIS
        
        Cost data is calculated from maintenance records.
        Please refer to the Maintenance section for detailed cost tracking.
        
        """
    }

    func saveReport(_ data: Data, filename: String) throws -> URL {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "PDFReportGenerator", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot access Documents directory"])
        }
        let reportsFolder = documentsPath.appendingPathComponent("GasGridManager Reports")

        try fileManager.createDirectory(at: reportsFolder, withIntermediateDirectories: true)

        let fileURL = reportsFolder.appendingPathComponent(filename)
        try data.write(to: fileURL, options: .atomic)

        return fileURL
    }
}
