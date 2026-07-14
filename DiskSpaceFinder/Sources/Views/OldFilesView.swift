import SwiftUI

struct OldFilesView: View {
    let node: FileNode
    let onNodeSelected: (FileNode) -> Void
    let onDelete: (FileNode) -> Void

    @State private var selectedFilter: AgeFilter = .lastYear
    @State private var fileToDelete: FileNode?

    private var filteredFiles: [FileNode] {
        let allFiles = node.allFiles()
        let calendar = Calendar.current
        let now = Date()

        return allFiles.filter { file in
            guard let date = file.modificationDate else {
                return selectedFilter == .unknown
            }

            switch selectedFilter {
            case .all:
                return true
            case .lastWeek:
                return calendar.dateComponents([.day], from: date, to: now).day ?? 0 <= 7
            case .lastMonth:
                return calendar.dateComponents([.month], from: date, to: now).month ?? 0 <= 1
            case .last3Months:
                return calendar.dateComponents([.month], from: date, to: now).month ?? 0 <= 3
            case .last6Months:
                return calendar.dateComponents([.month], from: date, to: now).month ?? 0 <= 6
            case .lastYear:
                return calendar.dateComponents([.year], from: date, to: now).year ?? 0 <= 1
            case .olderThan1Year:
                return calendar.dateComponents([.year], from: date, to: now).year ?? 0 > 1
            case .unknown:
                return file.modificationDate == nil
            }
        }.sorted { $0.size > $1.size }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            if filteredFiles.isEmpty {
                ContentUnavailableView(
                    "No Files Found",
                    systemImage: "clock",
                    description: Text("No files match the selected age filter")
                )
            } else {
                List(filteredFiles) { file in
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

    private var headerBar: some View {
        HStack {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(AgeFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 180)

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
