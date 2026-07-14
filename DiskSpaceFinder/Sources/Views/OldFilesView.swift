import SwiftUI

struct OldFilesView: View {
    let node: FileNode
    let onNodeSelected: (FileNode) -> Void
    let onDelete: (FileNode) -> Void

    @State private var selectedFilter: AgeFilter = .olderThan(value: 1, unit: .year)
    @State private var customValue: Int = 1
    @State private var customUnit: Calendar.Component = .year
    @State private var fileToDelete: FileNode?
    @State private var showCustomPicker = false
    @State private var filteredFiles: [FileNode] = []
    @State private var isFiltering = true

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            if isFiltering {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .frame(width: 20, height: 20)
                    Text("Filtering files...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if filteredFiles.isEmpty {
                ContentUnavailableView(
                    "No Files Found",
                    systemImage: "clock",
                    description: Text("No files match the selected age filter")
                )
            } else {
                List(filteredFiles.prefix(1000)) { file in
                    row(for: file)
                        .contextMenu {
                            Button {
                                NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
                            } label: {
                                Label("Open", systemImage: "arrow.right")
                            }

                            Button {
                                NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
                            } label: {
                                Label("Show in Finder", systemImage: "folder")
                            }

                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(file.path, forType: .string)
                            } label: {
                                Label("Copy Path", systemImage: "doc.on.doc")
                            }

                            Divider()

                            Button(role: .destructive) {
                                fileToDelete = file
                            } label: {
                                Label("Move to Trash", systemImage: "trash")
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
        .task(id: selectedFilter) {
            await applyFilter()
        }
        .alert("Delete File", isPresented: Binding(
            get: { fileToDelete != nil },
            set: { if !$0 { fileToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { fileToDelete = nil }
            Button("Move to Trash", role: .destructive) {
                if let file = fileToDelete {
                    onDelete(file)
                    fileToDelete = nil
                }
            }
        } message: {
            if let file = fileToDelete {
                Text("Are you sure you want to move \"\(file.name)\" to the Trash?")
            }
        }
    }

    private func applyFilter() async {
        isFiltering = true

        let allFiles = node.allFiles()
        let filter = selectedFilter
        let calendar = Calendar.current
        let now = Date()

        let filtered = await Task.detached(priority: .userInitiated) {
            allFiles.filter { file in
                guard let date = file.modificationDate else {
                    return filter == .unknown
                }

                switch filter {
                case .all:
                    return true
                case .olderThan(let value, let unit):
                    let components = calendar.dateComponents([unit], from: date, to: now)
                    let diff: Int
                    switch unit {
                    case .day: diff = components.day ?? 0
                    case .month: diff = components.month ?? 0
                    case .year: diff = components.year ?? 0
                    default: diff = components.day ?? 0
                    }
                    return diff >= value
                case .unknown:
                    return file.modificationDate == nil
                }
            }.sorted { $0.size > $1.size }
        }.value

        filteredFiles = filtered
        isFiltering = false
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            Menu {
                Button("All Files") { selectedFilter = .all }
                Button("Older Than 7 Days") { selectedFilter = .olderThan(value: 7, unit: .day) }
                Button("Older Than 30 Days") { selectedFilter = .olderThan(value: 30, unit: .day) }
                Button("Older Than 90 Days") { selectedFilter = .olderThan(value: 90, unit: .day) }
                Button("Older Than 6 Months") { selectedFilter = .olderThan(value: 6, unit: .month) }
                Button("Older Than 1 Year") { selectedFilter = .olderThan(value: 1, unit: .year) }
                Button("Older Than 2 Years") { selectedFilter = .olderThan(value: 2, unit: .year) }

                Divider()

                Button("Custom...") { showCustomPicker = true }

                Divider()

                Button("Unknown Date") { selectedFilter = .unknown }
            } label: {
                HStack {
                    Text(selectedFilter.displayName)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .cornerRadius(4)
            }
            .frame(width: 200)

            if showCustomPicker {
                HStack(spacing: 4) {
                    Text("Older than")
                        .font(.caption)

                    TextField("", value: $customValue, format: .number)
                        .frame(width: 40)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: customValue) { _, newValue in
                            selectedFilter = .olderThan(value: max(1, newValue), unit: customUnit)
                        }

                    Picker("", selection: $customUnit) {
                        Text("Days").tag(Calendar.Component.day)
                        Text("Months").tag(Calendar.Component.month)
                        Text("Years").tag(Calendar.Component.year)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                    .onChange(of: customUnit) { _, newValue in
                        selectedFilter = .olderThan(value: max(1, customValue), unit: newValue)
                    }

                    Button("Done") { showCustomPicker = false }
                        .font(.caption)
                }
            }

            Spacer()

            let totalSize = filteredFiles.reduce(Int64(0)) { $0 + $1.size }
            Text("\(filteredFiles.count) files")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                .font(.headline)
        }
        .padding()
        .background(.bar)
    }

    private func row(for file: FileNode) -> some View {
        HStack {
            Image(systemName: iconForFile(file))
                .foregroundStyle(colorForFile(file))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .lineLimit(1)
                Text(file.path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if let ext = file.fileExtension {
                Text(ext.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.quaternary)
                    .cornerRadius(3)
            }

            Text(file.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 60, alignment: .trailing)

            if let date = file.modificationDate {
                Text(date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .trailing)
            }
        }
    }

    private func iconForFile(_ node: FileNode) -> String {
        let category = FileCategory.categorize(fileExtension: node.fileExtension)
        switch category {
        case .documents: return "doc.text"
        case .images: return "photo"
        case .video: return "video"
        case .audio: return "music.note"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .archives: return "archivebox"
        case .applications: return "app"
        case .fonts: return "textformat"
        case .other: return "doc"
        }
    }

    private func colorForFile(_ node: FileNode) -> Color {
        let category = FileCategory.categorize(fileExtension: node.fileExtension)
        switch category {
        case .documents: return .blue
        case .images: return .green
        case .video: return .purple
        case .audio: return .orange
        case .code: return .cyan
        case .archives: return .brown
        case .applications: return .red
        case .fonts: return .pink
        case .other: return .gray
        }
    }
}
