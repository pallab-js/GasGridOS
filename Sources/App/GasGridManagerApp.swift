import SwiftUI
import GasGridManagerLib

@main
struct GasGridManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var selectedTab: SidebarView.SidebarTab = .dashboard
    @StateObject private var simulator = RealTimeSimulator()
    @StateObject private var notificationService = NotificationService.shared
    @State private var databaseError: String?

    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab, simulator: simulator)
                .frame(minWidth: 900, minHeight: 680)
                .onAppear {
                    setupDatabase()
                    simulator.startSimulation()
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
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1100, height: 800)

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
            if !stations.isEmpty {
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
                SidebarView(selectedTab: $selectedTab)
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
                }
            }
        } detail: {
            detailView
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
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

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task {
            await NotificationService.shared.requestAuthorization()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        DatabaseManager.shared.closeDatabase()
    }
}
