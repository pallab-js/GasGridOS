import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: SidebarTab
    @ObservedObject var simulator: RealTimeSimulator

    @AppStorage("showAlertBadges") private var showAlertBadges = true
    @StateObject private var alertViewModel = AlertViewModel()

    enum SidebarTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case network = "Network Map"
        case assets = "Assets"
        case valves = "Valves"
        case alerts = "Alerts"
        case maintenance = "Maintenance"
        case reports = "Reports"
        case export = "Export"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .network: return "map"
            case .assets: return "shippingbox"
            case .valves: return "lock.fill"
            case .alerts: return "bell"
            case .maintenance: return "wrench.and.screwdriver"
            case .reports: return "chart.bar"
            case .export: return "square.and.arrow.up"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        List(SidebarTab.allCases, selection: $selectedTab) { tab in
            if tab == .alerts && showAlertBadges && alertViewModel.unacknowledgedCount > 0 {
                HStack {
                    Label(tab.rawValue, systemImage: tab.icon)
                    Spacer()
                    Text("\(alertViewModel.unacknowledgedCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                        .foregroundColor(.white)
                        .accessibilityLabel("\(alertViewModel.unacknowledgedCount) unacknowledged alerts")
                }
                .tag(tab)
            } else {
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("GasGrid Manager")
        .task {
            await alertViewModel.loadData()
        }
        .onChange(of: simulator.lastUpdate) { _, _ in
            Task { await alertViewModel.loadData() }
        }
        .onChange(of: selectedTab) { _, _ in
            Task { await alertViewModel.loadData() }
        }
    }
}
