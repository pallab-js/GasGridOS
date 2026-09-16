import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("refreshInterval") private var refreshInterval = 5
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("enableSoundAlerts") private var enableSoundAlerts = true
    @AppStorage("showAlertBadges") private var showAlertBadges = true
    @AppStorage("autoRefresh") private var autoRefresh = true
    @State private var selectedTab: SettingsTab = .general
    @State private var showingClearAlert = false
    @State private var showingClearNotificationsAlert = false
    @State private var settingsError: String?
    @State private var containerWidth: CGFloat = 600
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var performanceMonitor = PerformanceMonitor.shared

    private var isCompact: Bool { containerWidth < 500 }

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case notifications = "Notifications"
        case appearance = "Appearance"
        case accessibility = "Accessibility"
        case keyboard = "Keyboard"
        case data = "Data"
        case performance = "Performance"
        case about = "About"

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .notifications: return "bell"
            case .appearance: return "paintbrush"
            case .accessibility: return "person.circle"
            case .keyboard: return "keyboard"
            case .data: return "externaldrive"
            case .performance: return "gauge.with.dots.needle.67percent"
            case .about: return "info.circle"
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if isCompact {
                    compactTabPicker
                } else {
                    regularTabPicker
                }

                Divider()

                ScrollView {
                    switch selectedTab {
                    case .general:
                        generalSettings
                    case .notifications:
                        notificationSettings
                    case .appearance:
                        appearanceSettings
                    case .accessibility:
                        AccessibilitySettingsView()
                    case .keyboard:
                        KeyboardShortcutsView()
                    case .data:
                        dataSettings
                    case .performance:
                        performanceSettings
                    case .about:
                        AboutView()
                    }
                }
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                containerWidth = newWidth
            }
            .onAppear {
                containerWidth = geometry.size.width
            }
        }
        .frame(minWidth: 420, minHeight: 400)
        .alert("Clear All Data", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will remove all historical data. This action cannot be undone.")
        }
        .alert("Clear Notifications", isPresented: $showingClearNotificationsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                notificationService.clearAllNotifications()
            }
        } message: {
            Text("This will clear all notifications. This action cannot be undone.")
        }
        .alert("Error", isPresented: .init(
            get: { settingsError != nil },
            set: { if !$0 { settingsError = nil } }
        )) {
            Button("OK") { settingsError = nil }
        } message: {
            Text(settingsError ?? "")
        }
    }

    private var regularTabPicker: some View {
        Picker("Settings", selection: $selectedTab) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    private var compactTabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.title3)
                            Text(tab.rawValue)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var generalSettings: some View {
        Form {
            Section("Data Refresh") {
                Toggle("Auto Refresh", isOn: $autoRefresh)

                Picker("Refresh Interval", selection: $refreshInterval) {
                    Text("1 second").tag(1)
                    Text("5 seconds").tag(5)
                    Text("10 seconds").tag(10)
                    Text("30 seconds").tag(30)
                    Text("60 seconds").tag(60)
                }
                .disabled(!autoRefresh)
            }

            Section("Display") {
                Toggle("Show Alert Badges", isOn: $showAlertBadges)
            }
        }
        .formStyle(.grouped)
    }

    private var notificationSettings: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $enableNotifications)
                    .onChange(of: enableNotifications) { _, newValue in
                        if newValue {
                            Task {
                                await notificationService.requestAuthorization()
                            }
                        }
                    }
                Toggle("Enable Sound Alerts", isOn: $enableSoundAlerts)

                HStack {
                    Text("Notification Status")
                    Spacer()
                    Text(notificationService.authorizationStatus == .authorized ? "Enabled" : "Disabled")
                        .foregroundColor(notificationService.authorizationStatus == .authorized ? .green : .secondary)
                }
            }

            Section("Alert Thresholds") {
                HStack {
                    Text("Critical Alert Sound")
                    Spacer()
                    Button("Play") {
                        playTestSound()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                HStack {
                    Text("Warning Alert Sound")
                    Spacer()
                    Button("Play") {
                        playTestSound()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Section("Actions") {
                Button(action: {
                    showingClearNotificationsAlert = true
                }) {
                    Label("Clear All Notifications", systemImage: "trash")
                }
            }
        }
        .formStyle(.grouped)
    }

    private var appearanceSettings: some View {
        Form {
            Section("Sidebar") {
                Toggle("Show Alert Count Badge", isOn: $showAlertBadges)
            }
        }
        .formStyle(.grouped)
    }

    private var dataSettings: some View {
        Form {
            Section("Data Management") {
                Button(action: { exportAllData() }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export All Data")
                    }
                }

                Button(action: {
                    NSWorkspace.shared.open(
                        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                            .appendingPathComponent("GasGridManager")
                    )
                }) {
                    HStack {
                        Image(systemName: "folder")
                        Text("Open Data Folder")
                    }
                }

                Button(action: { showingClearAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Historical Data")
                    }
                }
                .foregroundColor(.red)
            }

            Section("Database") {
                HStack {
                    Text("Database Size")
                    Spacer()
                    Text(getDatabaseSize())
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Last Backup")
                    Spacer()
                    Text("Never")
                        .foregroundColor(.secondary)
                }

                Button("Create Backup") {
                    createBackup()
                }
            }

            Section("Version") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Swift")
                    Spacer()
                    Text("6.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("macOS")
                    Spacer()
                    Text(ProcessInfo.processInfo.operatingSystemVersionString)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var performanceSettings: some View {
        Form {
            Section("System Monitoring") {
                Toggle("Enable Performance Monitoring", isOn: Binding(
                    get: { performanceMonitor.isMonitoring },
                    set: { newValue in
                        if newValue {
                            performanceMonitor.startMonitoring()
                        } else {
                            performanceMonitor.stopMonitoring()
                        }
                    }
                ))

                HStack {
                    Text("Memory Usage")
                    Spacer()
                    Text(String(format: "%.1f%%", performanceMonitor.memoryUsage))
                        .foregroundColor(performanceMonitor.memoryUsage > 80 ? .red : .secondary)
                }
            }

            Section("Build Information") {
                HStack {
                    Text("Swift Version")
                    Spacer()
                    Text("6.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("macOS Version")
                    Spacer()
                    Text(ProcessInfo.processInfo.operatingSystemVersionString)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Processor Count")
                    Spacer()
                    Text("\(ProcessInfo.processInfo.processorCount) cores")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func playTestSound() {
        NSSound.beep()
    }

    private func exportAllData() {
        let exportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("GasGridManager")
        NSWorkspace.shared.open(exportURL)
    }

    private func clearAllData() {
        DatabaseManager.shared.closeDatabase()
        do {
            try DatabaseManager.shared.openDatabase()
            try SampleDataSeeder.shared.seedSampleData()
        } catch {
            settingsError = "Failed to reset database: \(error.localizedDescription)"
        }
    }

    private func getDatabaseSize() -> String {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return "Unknown"
        }
        let dbPath = appSupport.appendingPathComponent("GasGridManager/gasgrid.sqlite")

        if let attributes = try? fileManager.attributesOfItem(atPath: dbPath.path),
           let size = attributes[.size] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: size)
        }
        return "Unknown"
    }

    private func createBackup() {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let dbPath = appSupport.appendingPathComponent("GasGridManager/gasgrid.sqlite")
        let backupPath = appSupport.appendingPathComponent("GasGridManager/gasgrid_backup_\(Int(Date().timeIntervalSince1970)).sqlite")
        
        DatabaseManager.shared.closeDatabase()
        do {
            try fileManager.copyItem(at: dbPath, to: backupPath)
            try DatabaseManager.shared.openDatabase()
        } catch {
            settingsError = "Failed to create backup: \(error.localizedDescription)"
            try? DatabaseManager.shared.openDatabase()
        }
    }
}
