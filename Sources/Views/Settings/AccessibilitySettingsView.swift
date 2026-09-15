import SwiftUI

struct AccessibilitySettingsView: View {
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("increaseContrast") private var increaseContrast = false
    @AppStorage("largerText") private var largerText = false
    @AppStorage("voiceOverEnabled") private var voiceOverEnabled = false
    @AppStorage("highContrastMode") private var highContrastMode = false

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
                        .help("Enhance visual distinction between elements")

                    Toggle("High Contrast Mode", isOn: $highContrastMode)
                        .help("Use high contrast colors for better visibility")

                    Toggle("Larger Text", isOn: $largerText)
                        .help("Use larger text throughout the app")
                }

                Section("VoiceOver") {
                    Toggle("Enable VoiceOver Hints", isOn: $voiceOverEnabled)
                        .help("Provide additional VoiceOver descriptions")

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
                        Text("All features can be accessed using keyboard shortcuts. Press ⌘ + ? to view all available shortcuts.")
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
