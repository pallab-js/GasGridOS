import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "flame.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text("GasGrid Manager")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("Professional Gas Distribution Network Management")
                .font(.body)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                AboutInfoRow(label: "Platform", value: "macOS \(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion)+")
                AboutInfoRow(label: "Framework", value: "SwiftUI")
                AboutInfoRow(label: "Language", value: "Swift 6.0")
                AboutInfoRow(label: "Database", value: "SQLite (GRDB.swift)")
                AboutInfoRow(label: "Architecture", value: "MVVM")
                AboutInfoRow(label: "Package Manager", value: "Swift Package Manager")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

            Text("© 2026 GasGrid Manager. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct AboutInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
