import SwiftUI

struct ExportView: View {
    @StateObject private var viewModel = ExportViewModel()
    @State private var selectedFormat: ExportViewModel.ExportFormat = .csv
    @State private var selectedType: ExportViewModel.ExportType = .all

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            exportOptions

            Divider()

            previewSection

            Divider()

            exportStatus

            Spacer()
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Export Data")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Export network data for analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let path = viewModel.exportedFilePath {
                Button(action: {
                    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                }) {
                    Label("Open Folder", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Open the folder containing the exported file")
            }
        }
        .padding()
    }

    private var exportOptions: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Export Options")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                Text("Data Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Data Type", selection: $selectedType) {
                    ForEach(ExportViewModel.ExportType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: iconForType(type))
                            Text(type.rawValue)
                        }.tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Format")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Format", selection: $selectedFormat) {
                    ForEach(ExportViewModel.ExportFormat.allCases, id: \.self) { format in
                        HStack {
                            Image(systemName: iconForFormat(format))
                            Text(format.rawValue)
                        }.tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await viewModel.exportData(format: selectedFormat, type: selectedType)
                    }
                }) {
                    HStack {
                        if viewModel.isExporting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(viewModel.isExporting ? "Exporting..." : "Export Now")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isExporting)
            }
        }
        .padding()
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Export Preview")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.previewCount) records will be exported")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.previewData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No data to preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.previewData.prefix(5), id: \.self) { item in
                            Text(item)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)
                        }
                        if viewModel.previewData.count > 5 {
                            Text("... and \(viewModel.previewData.count - 5) more records")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 100)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding()
    }

    private var exportStatus: some View {
        VStack(spacing: 16) {
            if viewModel.isExporting {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.exportProgress)
                        .progressViewStyle(.linear)
                    Text("Exporting data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            if viewModel.exportComplete {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Export Complete")
                            .font(.headline)
                        Text(viewModel.exportedFilePath ?? "File saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button("Open") {
                        if let path = viewModel.exportedFilePath {
                            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
    }

    private func iconForType(_ type: ExportViewModel.ExportType) -> String {
        switch type {
        case .stations: return "building.2"
        case .pipelines: return "cable.connector"
        case .alerts: return "bell"
        case .all: return "square.grid.2x2"
        }
    }

    private func iconForFormat(_ format: ExportViewModel.ExportFormat) -> String {
        switch format {
        case .csv: return "tablecells"
        case .json: return "doc.text"
        case .pdf: return "doc.richtext"
        }
    }
}
