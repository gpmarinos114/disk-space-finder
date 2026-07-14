import SwiftUI

struct DuplicateFilesView: View {
    let node: FileNode

    @State private var duplicateGroups: [DuplicateDetector.DuplicateGroup] = []
    @State private var isScanning = false
    @State private var quickScan = true

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            if isScanning {
                ProgressView("Scanning for duplicates...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if duplicateGroups.isEmpty {
                ContentUnavailableView(
                    "No Duplicates Found",
                    systemImage: "checkmark.circle",
                    description: Text("No duplicate files were found in this directory")
                )
            } else {
                List(duplicateGroups) { group in
                    DuplicateGroupRow(group: group)
                }
            }
        }
        .task {
            await scanForDuplicates()
        }
    }

    @ViewBuilder
    private var headerBar: some View {
        HStack {
            Toggle("Quick Scan (name + size)", isOn: $quickScan)
                .toggleStyle(.switch)
                .onChange(of: quickScan) { _ in
                    Task { await scanForDuplicates() }
                }

            Spacer()

            let totalWasted = duplicateGroups.reduce(Int64(0)) { $0 + $1.wastedSpace }
            if totalWasted > 0 {
                Text("Wasted: \(ByteCountFormatter.string(fromByteCount: totalWasted, countStyle: .file))")
                    .font(.headline)
                    .foregroundStyle(.red)
            }

            Button("Rescan") {
                Task { await scanForDuplicates() }
            }
            .disabled(isScanning)
        }
        .padding()
        .background(.bar)
    }

    private func scanForDuplicates() async {
        isScanning = true
        let detector = DuplicateDetector()

        if quickScan {
            duplicateGroups = detector.findQuickDuplicates(in: node)
        } else {
            duplicateGroups = await detector.findDuplicates(in: node)
        }

        isScanning = false
    }
}

struct DuplicateGroupRow: View {
    let group: DuplicateDetector.DuplicateGroup

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(group.files) { file in
                HStack {
                    Image(systemName: "doc")
                        .foregroundStyle(.secondary)
                    Text(file.path)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button {
                        NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
                    } label: {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 2)
            }
        } label: {
            HStack {
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(.orange)
                Text(group.files.first?.name ?? "Unknown")
                    .fontWeight(.medium)
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: group.size, countStyle: .file))
                    .foregroundStyle(.secondary)
                Text("\(group.files.count) copies")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.2))
                    .cornerRadius(4)
                Text("Wasted: \(ByteCountFormatter.string(fromByteCount: group.wastedSpace, countStyle: .file))")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
