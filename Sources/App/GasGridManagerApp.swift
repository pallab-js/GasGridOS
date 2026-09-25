import SwiftUI
import Combine

@main
struct GasGridManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var selectedTab: SidebarView.SidebarTab = .dashboard
    @StateObject private var simulator = RealTimeSimulator()
    @StateObject private var notificationService = NotificationService.shared
    @State private var databaseError: String?
    @State private var didInitialize = false

    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab, simulator: simulator)
                .frame(minWidth: 900, minHeight: 680)
                .onAppear {
                    guard !didInitialize else { return }
                    didInitialize = true
                    setupDatabase()
                    simulator.startSimulation()
                    simulator.onAlertGenerated = { alert in
                        NotificationService.shared.sendAlertNotification(alert: alert)
                    }
                    Task {
                        await notificationService.checkAuthorization()
                    }
                }
                .alert("Database Error", isPresented: .init(
                    get: { databaseError != nil },
                    set: { if !$0 { databaseError = nil } }
                )) {
                    Button("OK") { databaseError = nil }
                } message: {
                    Text(databaseError ?? "")
                }
                .onDisappear {
                    simulator.stopSimulation()
                }
        }
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1100, height: 800)
        .commands {
            CommandMenu("Navigate") {
                ForEach(Array(SidebarView.SidebarTab.allCases.enumerated()), id: \.element.id) { index, tab in
                    Button(tab.rawValue) {
                        selectedTab = tab
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
            }

            CommandGroup(after: .saveItem) {
                Button("Refresh Data") {
                    NotificationCenter.default.post(name: .gasGridRefreshData, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Export Data") {
                    selectedTab = .export
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .frame(minWidth: 420, minHeight: 400)
        }
        #endif
    }

    private func setupDatabase() {
        do {
            try DatabaseManager.shared.openDatabase()
            try SampleDataSeeder.shared.seedSampleData()
            let stations = try StationRepository().fetchAll()
            try SampleDataSeeder.shared.ensureTelemetrySensors(for: stations)

            let historyRepo = DataHistoryRepository()
            try historyRepo.deleteOrphanedReadings()

            let calendar = Calendar.current
            let now = Date()
            if !stations.isEmpty,
               let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
               try historyRepo.countInTimeRange(startDate: weekAgo, endDate: now) == 0 {
                HistoryGenerator.shared.generateHistoryData(for: stations, days: 7)
            }
        } catch {
            databaseError = "Failed to initialize database: \(error.localizedDescription)"
        }
    }
}

struct ContentView: View {
    @Binding var selectedTab: SidebarView.SidebarTab
    @ObservedObject var simulator: RealTimeSimulator

    var body: some View {
        NavigationSplitView {
            VStack {
                SidebarView(selectedTab: $selectedTab, simulator: simulator)
                    .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)

                if simulator.isRunning {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("Live")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Live simulation running")
                }
            }
        } detail: {
            detailView
        }
        .modifier(AccessibilityPreferences())
        .onReceive(NotificationCenter.default.publisher(for: .gasGridOpenAlert)) { _ in
            selectedTab = .alerts
        }
        .alert("Simulation Error", isPresented: .init(
            get: { simulator.errorMessage != nil },
            set: { if !$0 { simulator.errorMessage = nil } }
        )) {
            Button("OK") { simulator.errorMessage = nil }
        } message: {
            Text(simulator.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView(selectedTab: $selectedTab)
        case .network:
            NetworkMapView()
        case .assets:
            AssetListView()
        case .valves:
            ValveListView()
        case .alerts:
            AlertListView()
        case .maintenance:
            MaintenanceListView()
        case .reports:
            ReportListView()
        case .export:
            ExportView()
        case .settings:
            SettingsView()
        }
    }
}

/// Applies the user's accessibility preferences app-wide.
private struct AccessibilityPreferences: ViewModifier {
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("largerText") private var largerText = false
    @AppStorage("increaseContrast") private var increaseContrast = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @ViewBuilder
    func body(content: Content) -> some View {
        let prepared = content
            .transaction { transaction in
                if reduceMotion || systemReduceMotion {
                    transaction.disablesAnimations = true
                }
            }
            .environment(\.legibilityWeight, increaseContrast ? .bold : .regular)

        if largerText {
            prepared.dynamicTypeSize(.accessibility1)
        } else {
            prepared
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Keeps raw UserDefaults reads consistent with the @AppStorage defaults
        // used by SettingsView and AccessibilitySettingsView.
        UserDefaults.standard.register(defaults: [
            "refreshInterval": 5,
            "enableNotifications": true,
            "enableSoundAlerts": true,
            "showAlertBadges": true,
            "autoRefresh": true,
            "reduceMotion": false,
            "increaseContrast": false,
            "largerText": false
        ])
    }

    func applicationWillTerminate(_ notification: Notification) {
        DatabaseManager.shared.closeDatabase()
    }
}
