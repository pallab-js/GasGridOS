import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("refreshInterval") private var refreshInterval = 5
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("enableSoundAlerts") private var enableSoundAlerts = true
    @AppStorage("showAlertBadges") private var showAlertBadges = true
    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("lastBackupDate") private var lastBackupDate: Double = 0
    @State private var selectedTab: SettingsTab = .general
    @State private var showingClearAlert = false
    @State private var showingClearNotificationsAlert = false
    @State private var settingsError: String?
    @State private var settingsSuccess: String?
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
        .alert("Clear Historical Data", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will delete all recorded sensor history. Stations, pipelines, alerts and settings are kept.")
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
        .alert("Success", isPresented: .init(
            get: { settingsSuccess != nil },
            set: { if !$0 { settingsSuccess = nil } }
        )) {
            Button("OK") { settingsSuccess = nil }
        } message: {
            Text(settingsSuccess ?? "")
        }
        .task {
            await notificationService.checkAuthorization()
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

                Text("Controls how often the dashboard reloads live data.")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                    Text(notificationStatusText)
                        .foregroundColor(notificationService.authorizationStatus == .authorized ? .green : .secondary)
                }
            }

            Section("Alert Sounds") {
                HStack {
                    Text("Critical Alert Sound")
                    Spacer()
                    Button("Play") {
                        playTestSound(named: "Sosumi")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                HStack {
                    Text("Warning Alert Sound")
                    Spacer()
                    Button("Play") {
                        playTestSound(named: "Ping")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Text("Sound alerts can be turned off with \"Enable Sound Alerts\" above.")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

    private var notificationStatusText: String {
        switch notificationService.authorizationStatus {
        case .authorized: return "Enabled"
        case .denied: return "Disabled (permission denied)"
        case .notDetermined: return "Not requested yet"
        case .provisional: return "Enabled (provisional)"
        case .ephemeral: return "Enabled (temporary)"
        @unknown default: return "Unknown"
        }
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
                        Text("Export All Data (JSON)")
                    }
                }

                Button(action: {
                    if let folder = DatabaseManager.databaseDirectoryURL {
                        NSWorkspace.shared.open(folder)
                    } else {
                        settingsError = "Cannot locate the application data folder."
                    }
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
                    Text(lastBackupText)
                        .foregroundColor(.secondary)
                }

                Button("Create Backup") {
                    createBackup()
                }
            }
        }
        .formStyle(.grouped)
    }

    private var lastBackupText: String {
        guard lastBackupDate > 0 else { return "Never" }
        return Date(timeIntervalSince1970: lastBackupDate)
            .formatted(date: .abbreviated, time: .shortened)
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

            Section("System") {
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

    private func playTestSound(named name: String) {
        if let sound = NSSound(named: NSSound.Name(name)) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    private func exportAllData() {
        Task {
            let exporter = ExportViewModel()
            await exporter.exportData(format: .json, type: .all)
            if let path = exporter.exportedFilePath {
                settingsSuccess = "Exported to \(path)"
            } else {
                settingsError = exporter.errorMessage ?? "Export failed."
            }
        }
    }

    private func clearAllData() {
        do {
            try DatabaseManager.shared.clearHistoricalData()
            DatabaseManager.shared.logAuditEvent("CLEAR_HISTORICAL_DATA", details: "User cleared all historical sensor data")
            settingsSuccess = "Historical data cleared."
        } catch {
            settingsError = "Failed to clear historical data: \(error.localizedDescription)"
        }
    }

    private func getDatabaseSize() -> String {
        let fileManager = FileManager.default
        guard let dbFile = DatabaseManager.databaseFileURL else { return "Unknown" }

        if let attributes = try? fileManager.attributesOfItem(atPath: dbFile.path),
           let size = attributes[.size] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: size)
        }
        return "Unknown"
    }

    private func createBackup() {
        guard let directory = DatabaseManager.databaseDirectoryURL else {
            settingsError = "Cannot locate the application data folder."
            return
        }
        let backupName = "gasgrid_backup_\(Int(Date().timeIntervalSince1970)).sqlite"
        let backupURL = directory.appendingPathComponent(backupName)

        do {
            try DatabaseManager.shared.backup(to: backupURL)
            lastBackupDate = Date().timeIntervalSince1970
            settingsSuccess = "Backup created: \(backupName)"
        } catch {
            settingsError = "Failed to create backup: \(error.localizedDescription)"
        }
    }
}
