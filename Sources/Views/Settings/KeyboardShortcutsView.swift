import SwiftUI

struct KeyboardShortcutsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Navigation") {
                    ShortcutRow(shortcut: "⌘ + 1", action: "Dashboard")
                    ShortcutRow(shortcut: "⌘ + 2", action: "Network Map")
                    ShortcutRow(shortcut: "⌘ + 3", action: "Assets")
                    ShortcutRow(shortcut: "⌘ + 4", action: "Valves")
                    ShortcutRow(shortcut: "⌘ + 5", action: "Alerts")
                    ShortcutRow(shortcut: "⌘ + 6", action: "Maintenance")
                    ShortcutRow(shortcut: "⌘ + 7", action: "Reports")
                    ShortcutRow(shortcut: "⌘ + 8", action: "Export")
                    ShortcutRow(shortcut: "⌘ + 9", action: "Settings")
                }

                Section("Actions") {
                    ShortcutRow(shortcut: "⌘ + R", action: "Refresh Data")
                    ShortcutRow(shortcut: "⌘ + E", action: "Export Data")
                    ShortcutRow(shortcut: "⌘ + ,", action: "Preferences")
                    ShortcutRow(shortcut: "Esc", action: "Close Sheet")
                }
            }
            .formStyle(.grouped)
        }
        .padding()
    }
}

struct ShortcutRow: View {
    let shortcut: String
    let action: String

    var body: some View {
        HStack {
            Text(action)
                .frame(minWidth: 160, alignment: .leading)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(action), keyboard shortcut \(shortcut)")
    }
}
