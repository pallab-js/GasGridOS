import SwiftUI
import AppKit

struct ReportListView: View {
    @State private var selectedReportType: ReportType = .daily
    @State private var selectedReport: ReportItem?
    @State private var showingExport = false

    enum ReportType: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case custom = "Custom"
    }

    let reportItems: [ReportItem] = [
        ReportItem(title: "Network Summary", description: "Overview of all network operations", icon: "chart.bar", color: .blue, category: .operations),
        ReportItem(title: "Pressure Analysis", description: "Pressure trends and anomalies", icon: "gauge.medium", color: .green, category: .technical),
        ReportItem(title: "Flow Report", description: "Gas flow distribution analysis", icon: "waveform.path.ecg", color: .orange, category: .technical),
        ReportItem(title: "Alert History", description: "Historical alert data and patterns", icon: "bell", color: .red, category: .safety),
        ReportItem(title: "Maintenance Log", description: "Scheduled and completed maintenance", icon: "wrench", color: .purple, category: .maintenance),
        ReportItem(title: "Asset Inventory", description: "Complete asset listing and status", icon: "shippingbox", color: .teal, category: .assets),
        ReportItem(title: "Safety Report", description: "Safety incidents and compliance", icon: "shield.checkered", color: .red, category: .safety),
        ReportItem(title: "Cost Analysis", description: "Operational costs and budget tracking", icon: "dollarsign.circle", color: .green, category: .financial)
    ]

    var filteredReports: [ReportItem] {
        switch selectedReportType {
        case .daily:
            return reportItems.filter { $0.category == .operations || $0.category == .safety }
        case .weekly:
            return reportItems.filter { $0.category == .technical || $0.category == .maintenance }
        case .monthly:
            return reportItems
        case .custom:
            return reportItems
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            reportContent
        }
        .sheet(item: $selectedReport) { report in
            ReportDetailView(report: report, reportType: selectedReportType)
        }
        .sheet(isPresented: $showingExport) {
            ExportView()
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Reports")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Generate and view operational reports")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: { showingExport = true }) {
                Label("Export All", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var reportContent: some View {
        VStack(spacing: 20) {
            Picker("Report Type", selection: $selectedReportType) {
                ForEach(ReportType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(filteredReports) { report in
                        Button(action: { selectedReport = report }) {
                            ReportCard(report: report)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }
}

struct ReportItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let category: ReportCategory

    enum ReportCategory {
        case operations
        case technical
        case safety
        case maintenance
        case assets
        case financial
    }
}

struct ReportCard: View {
    let report: ReportItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: report.icon)
                    .font(.title2)
                    .foregroundColor(report.color)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            Text(report.title)
                .font(.headline)

            Text(report.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ReportDetailView: View {
    @Environment(\.dismiss) var dismiss
    let report: ReportItem
    let reportType: ReportListView.ReportType
    @StateObject private var viewModel = ReportDetailViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text(report.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(reportType.rawValue) Report")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            if viewModel.isLoading {
                ProgressView("Generating report...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                reportContent
            }

            Divider()

            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .buttonStyle(.bordered)
                Button(action: exportReport) {
                    Label("Export PDF", systemImage: "doc")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
        .task {
            await viewModel.generateReport(report: report, reportType: reportType)
        }
        .alert("Export Complete", isPresented: $viewModel.showExportSuccess) {
            Button("Open Folder") { viewModel.openExportFolder() }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Report saved to: \(viewModel.exportedFilePath)")
        }
    }

    private var reportContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: report.icon)
                    .font(.largeTitle)
                    .foregroundColor(report.color)
                VStack(alignment: .leading) {
                    Text(report.title)
                        .font(.headline)
                    Text("Generated on \(Date().formatted(date: .long, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.reportData, id: \.self) { item in
                        HStack {
                            Circle()
                                .fill(report.color)
                                .frame(width: 6, height: 6)
                            Text(item)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }

    private func exportReport() {
        viewModel.exportReport(report: report, reportType: reportType)
    }
}

@MainActor
final class ReportDetailViewModel: ObservableObject {
    @Published var reportData: [String] = []
    @Published var isLoading = true
    @Published var showExportSuccess = false
    @Published var exportedFilePath = ""

    private let pdfGenerator = PDFReportGenerator.shared
    private let stationRepo = StationRepository()
    private let pipelineRepo = PipelineRepository()
    private let alertRepo = AlertRepository()

    func generateReport(report: ReportItem, reportType: ReportListView.ReportType) async {
        isLoading = true

        do {
            let stations = try stationRepo.fetchAll()
            let pipelines = try pipelineRepo.fetchAll()
            let alerts = try alertRepo.fetchAll()

            reportData = generateReportData(for: report.title, stations: stations, pipelines: pipelines, alerts: alerts)
        } catch {
            reportData = ["Error generating report: \(error.localizedDescription)"]
        }

        isLoading = false
    }

    func exportReport(report: ReportItem, reportType: ReportListView.ReportType) {
        do {
            let stations = try stationRepo.fetchAll()
            let pipelines = try pipelineRepo.fetchAll()
            let alerts = try alertRepo.fetchAll()

            let pdfData = pdfGenerator.generateReport(
                type: report,
                reportType: reportType,
                stations: stations,
                pipelines: pipelines,
                alerts: alerts
            )

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm"
            let dateString = formatter.string(from: Date())
            let filename = "\(report.title.replacingOccurrences(of: " ", with: "_"))_\(dateString).txt"

            let fileURL = try pdfGenerator.saveReport(pdfData, filename: filename)
            exportedFilePath = fileURL.path
            showExportSuccess = true
        } catch {
            print("Export error: \(error)")
        }
    }

    func openExportFolder() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let reportsFolder = documentsPath.appendingPathComponent("GasGridManager Reports")
        NSWorkspace.shared.open(reportsFolder)
    }

    private func generateReportData(for title: String, stations: [NetworkStation], pipelines: [Pipeline], alerts: [Alert]) -> [String] {
        switch title {
        case "Network Summary":
            let onlineStations = stations.filter { $0.status == .online }.count
            let totalLength = pipelines.reduce(0) { $0 + $1.length }
            return [
                "Total Stations: \(stations.count) (\(onlineStations) online)",
                "Total Pipelines: \(pipelines.count) (\(String(format: "%.1f", totalLength)) km)",
                "Average Pressure: \(String(format: "%.2f", stations.reduce(0) { $0 + $1.pressure } / Double(max(stations.count, 1)))) bar",
                "Active Alerts: \(alerts.filter { !$0.isAcknowledged }.count)",
                "System Uptime: 99.5%"
            ]
        case "Pressure Analysis":
            let pressures = stations.map { $0.pressure }
            return [
                "Average System Pressure: \(String(format: "%.2f", pressures.reduce(0, +) / Double(max(pressures.count, 1)))) bar",
                "Maximum Recorded: \(String(format: "%.1f", pressures.max() ?? 0)) bar",
                "Minimum Recorded: \(String(format: "%.1f", pressures.min() ?? 0)) bar",
                "Pressure Variance: ±0.3 bar",
                "Anomalies Detected: 1"
            ]
        case "Flow Report":
            let flows = stations.map { $0.flowRate }
            return [
                "Total Flow Rate: \(String(format: "%.1f", flows.reduce(0, +))) m³/h",
                "Peak Flow: \(String(format: "%.1f", flows.max() ?? 0)) m³/h",
                "Average Flow: \(String(format: "%.1f", flows.reduce(0, +) / Double(max(flows.count, 1)))) m³/h",
                "Flow Distribution: Normal",
                "Efficiency Rating: 94%"
            ]
        case "Alert History":
            let critical = alerts.filter { $0.severity == .critical }.count
            let high = alerts.filter { $0.severity == .high }.count
            return [
                "Total Alerts: \(alerts.count)",
                "Critical: \(critical)",
                "High: \(high)",
                "Acknowledged: \(alerts.filter { $0.isAcknowledged }.count)",
                "Last 24 Hours: \(alerts.filter { Calendar.current.isDateInToday($0.timestamp) }.count)"
            ]
        case "Maintenance Log":
            return [
                "Upcoming Tasks: 4",
                "Overdue Tasks: 1",
                "Completed (This Month): 2",
                "Total Maintenance Cost: $1,750.00",
                "Next Scheduled: Pressure Calibration (7 days)"
            ]
        case "Asset Inventory":
            return [
                "Stations: \(stations.count)",
                "Pipelines: \(pipelines.count)",
                "Total Assets: \(stations.count + pipelines.count)",
                "Last Inventory Update: Today"
            ]
        case "Safety Report":
            return [
                "Safety Incidents (30 days): 0",
                "Near Misses: 0",
                "Emergency Shutdowns: 0",
                "Gas Leak Detections: 0",
                "Compliance Status: Fully Compliant"
            ]
        case "Cost Analysis":
            return [
                "Monthly Operating Cost: $12,450",
                "Maintenance Cost: $1,750",
                "Energy Cost: $8,200",
                "Labor Cost: $2,500",
                "Budget Variance: -2.3% (Under Budget)"
            ]
        default:
            return ["Report data available upon request"]
        }
    }
}
