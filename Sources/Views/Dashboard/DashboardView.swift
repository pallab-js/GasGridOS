import SwiftUI
import Combine

struct DashboardView: View {
    @Binding var selectedTab: SidebarView.SidebarTab
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var chartViewModel = ChartViewModel()
    @State private var selectedTimeRange: ChartViewModel.TimeRange = .lastHour
    @State private var containerWidth: CGFloat = 1400

    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("refreshInterval") private var refreshInterval = 5

    private var isCompact: Bool { containerWidth < 1100 }

    private var kpiColumns: [GridItem] {
        isCompact
            ? [GridItem(.adaptive(minimum: 200))]
            : Array(repeating: GridItem(.flexible()), count: 4)
    }

    private var chartColumns: [GridItem] {
        isCompact
            ? [GridItem(.adaptive(minimum: 280))]
            : Array(repeating: GridItem(.flexible()), count: 3)
    }

    private var chartHeight: CGFloat { isCompact ? 120 : 150 }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading && viewModel.stations.isEmpty {
                        loadingView
                    } else if viewModel.stations.isEmpty {
                        emptyStateView
                    } else {
                        headerSection
                        kpiSection
                        chartsSection

                        if isCompact {
                            VStack(alignment: .leading, spacing: 20) {
                                alertSummarySection
                                systemStatusSection
                            }
                        } else {
                            HStack(alignment: .top, spacing: 20) {
                                alertSummarySection
                                    .frame(maxWidth: .infinity)
                                systemStatusSection
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        stationPerformanceSection
                        networkOverviewSection
                    }
                }
                .padding()
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                containerWidth = newWidth
            }
            .onAppear {
                containerWidth = geometry.size.width
            }
        }
        .task {
            await viewModel.loadData()
            await chartViewModel.loadHistoricalData(timeRange: selectedTimeRange)

            // Keep KPIs in step with the simulator using the interval the
            // user configured in Settings > General > Data Refresh.
            while !Task.isCancelled {
                let interval = max(1, refreshInterval)
                try? await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
                if Task.isCancelled { break }
                guard autoRefresh else { continue }
                await viewModel.loadData()
            }
        }
        .refreshable {
            await viewModel.loadData()
            await chartViewModel.loadHistoricalData(timeRange: selectedTimeRange)
        }
        .onReceive(NotificationCenter.default.publisher(for: .gasGridRefreshData)) { _ in
            Task {
                await viewModel.loadData()
                await chartViewModel.loadHistoricalData(timeRange: selectedTimeRange)
            }
        }
        .alert("Dashboard Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Chart Error", isPresented: .init(
            get: { chartViewModel.errorMessage != nil },
            set: { if !$0 { chartViewModel.errorMessage = nil } }
        )) {
            Button("OK") { chartViewModel.errorMessage = nil }
        } message: {
            Text(chartViewModel.errorMessage ?? "")
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading dashboard data...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(100)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Data Available")
                .font(.title2)
                .fontWeight(.bold)

            Text("Start by adding stations and pipelines to your network")
                .foregroundColor(.secondary)

            Text("The dashboard will display real-time metrics once data is available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(100)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Real-time monitoring overview")
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(autoRefresh ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(autoRefresh ? "Live" : "Paused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(autoRefresh ? "Live updates enabled" : "Live updates paused")
                Text("Last Updated")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.lastUpdated, style: .time)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }

    private var kpiSection: some View {
        DisclosureGroup {
            LazyVGrid(columns: kpiColumns, spacing: 16) {
                KPICardView(
                    title: "Avg Pressure",
                    value: String(format: "%.2f bar", viewModel.averagePressure),
                    icon: "gauge.medium",
                    color: .blue,
                    trend: formatTrend(viewModel.pressureTrend, unit: "bar"),
                    isPositiveTrend: trendDirection(viewModel.pressureTrend)
                )

                KPICardView(
                    title: "Avg Flow Rate",
                    value: String(format: "%.1f m³/h", viewModel.averageFlowRate),
                    icon: "waveform.path.ecg",
                    color: .green,
                    trend: formatTrend(viewModel.flowRateTrend, unit: "m³/h"),
                    isPositiveTrend: trendDirection(viewModel.flowRateTrend)
                )

                KPICardView(
                    title: "Avg Temperature",
                    value: String(format: "%.1f°C", viewModel.averageTemperature),
                    icon: "thermometer.medium",
                    color: .orange,
                    trend: formatTrend(viewModel.temperatureTrend, unit: "°C"),
                    isPositiveTrend: trendDirection(viewModel.temperatureTrend)
                )

                KPICardView(
                    title: "Active Alerts",
                    value: "\(viewModel.criticalAlerts + viewModel.warningAlerts)",
                    icon: "bell.fill",
                    color: viewModel.criticalAlerts > 0 ? .red : .green
                )
            }
        } label: {
            Text("Key Metrics")
                .font(.headline)
        }
    }

    private func formatTrend(_ value: Double, unit: String) -> String {
        let clamped = abs(value) < 0.005 ? 0 : value
        let sign = clamped > 0 ? "+" : (clamped < 0 ? "-" : "")
        return "\(sign)\(String(format: "%.2f", abs(clamped))) \(unit)"
    }

    /// `nil` for a flat trend so the card shows no misleading arrow.
    private func trendDirection(_ value: Double) -> Bool? {
        if value > 0.005 { return true }
        if value < -0.005 { return false }
        return nil
    }

    private var chartsSection: some View {
        DisclosureGroup {
            VStack(spacing: 16) {
                TimeRangePicker(selectedRange: $selectedTimeRange)
                    .onChange(of: selectedTimeRange) { _, _ in
                        Task {
                            await chartViewModel.loadHistoricalData(timeRange: selectedTimeRange)
                        }
                    }

                LazyVGrid(columns: chartColumns, spacing: 16) {
                    if chartViewModel.isLoading && chartViewModel.pressureHistory.isEmpty {
                        ProgressView("Loading charts...")
                            .frame(maxWidth: .infinity)
                            .frame(height: chartHeight)
                    } else {
                        PressureChartView(
                            data: chartViewModel.pressureHistory,
                            unit: "bar",
                            chartHeight: chartHeight
                        )

                        FlowRateChartView(
                            data: chartViewModel.flowRateHistory,
                            unit: "m³/h",
                            chartHeight: chartHeight
                        )

                        TemperatureChartView(
                            data: chartViewModel.temperatureHistory,
                            unit: "°C",
                            chartHeight: chartHeight
                        )
                    }
                }
            }
        } label: {
            Text("Charts")
                .font(.headline)
        }
    }

    private var alertSummarySection: some View {
        AlertSummaryView(alerts: viewModel.alerts, selectedTab: $selectedTab)
    }

    private var systemStatusSection: some View {
        SystemStatusView(
            stations: viewModel.stations,
            pipelines: viewModel.pipelines,
            sensors: viewModel.sensors
        )
    }

    private var stationPerformanceSection: some View {
        DisclosureGroup {
            StationPerformanceView(stations: viewModel.stations)
        } label: {
            Text("Station Performance")
                .font(.headline)
        }
    }

    private var networkOverviewSection: some View {
        DisclosureGroup {
            NetworkOverviewView(
                stations: viewModel.stations,
                pipelines: viewModel.pipelines,
                isCompact: isCompact
            )
        } label: {
            Text("Network Overview")
                .font(.headline)
        }
    }
}
