import SwiftUI

struct AccessibilitySettingsView: View {
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("increaseContrast") private var increaseContrast = false
    @AppStorage("largerText") private var largerText = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Accessibility")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                Section("Visual") {
                    Toggle("Reduce Motion", isOn: $reduceMotion)
                        .help("Minimize animations and transitions")

                    Toggle("Increase Contrast", isOn: $increaseContrast)
                        .help("Render text with a heavier weight for better legibility")

                    Toggle("Larger Text", isOn: $largerText)
                        .help("Use larger text throughout the app")
                }

                Section("System Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("For system-wide display options such as increased contrast, bold text and VoiceOver, use macOS System Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Open Accessibility Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Section("VoiceOver") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VoiceOver Support")
                            .font(.subheadline)
                        Text("All UI elements in GasGrid Manager support VoiceOver navigation. Use standard VoiceOver gestures to navigate through the app.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Keyboard Navigation") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Keyboard Access")
                            .font(.subheadline)
                        Text("All features can be accessed using keyboard shortcuts. See the Keyboard tab for the list of available shortcuts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .padding()
    }
}
