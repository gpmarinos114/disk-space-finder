import SwiftUI

struct ScanHistoryView: View {
    let historyManager = ScanHistoryManager()
    @State private var snapshots: [ScanSnapshot] = []
    @State private var snapshot1: ScanSnapshot?
    @State private var snapshot2: ScanSnapshot?
    @State private var showComparison = false
    @State private var isSelectingForCompare = false

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            if snapshots.isEmpty {
                ContentUnavailableView(
                    "No Scan History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Complete a scan to save it to history")
                )
            } else {
                List(snapshots.sorted { $0.date > $1.date }) { snapshot in
                    row(for: snapshot)
                        .contextMenu {
                            Button {
                                snapshot1 = snapshot
                                isSelectingForCompare = true
                            } label: {
                                Label("Compare With...", systemImage: "arrow.left.arrow.right")
                            }

                            Divider()

                            Button(role: .destructive) {
                                historyManager.delete(snapshot)
                                snapshots = historyManager.loadAll()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
        .onAppear {
            snapshots = historyManager.loadAll()
        }
        .sheet(isPresented: $isSelectingForCompare) {
            ComparePickerView(
                snapshots: snapshots.sorted { $0.date > $1.date },
                excludedSnapshot: snapshot1,
                onSelect: { selected in
                    snapshot2 = selected
                    isSelectingForCompare = false
                    showComparison = true
                },
                onCancel: {
                    isSelectingForCompare = false
                }
            )
        }
        .sheet(isPresented: $showComparison) {
            if let s1 = snapshot1, let s2 = snapshot2 {
                ScanComparisonView(snapshot1: s1, snapshot2: s2)
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Text("Scan History")
                .font(.headline)

            Spacer()

            if isSelectingForCompare {
                Text("Select a scan to compare with")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Text("\(snapshots.count) scans")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.bar)
    }

    private func row(for snapshot: ScanSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.rootPath)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(snapshot.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(ByteCountFormatter.string(fromByteCount: snapshot.totalSize, countStyle: .file))
                    .font(.headline)

                Text("\(snapshot.fileCount.formatted()) files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ComparePickerView: View {
    let snapshots: [ScanSnapshot]
    let excludedSnapshot: ScanSnapshot?
    let onSelect: (ScanSnapshot) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Select Scan to Compare")
                    .font(.headline)
                Spacer()
                Button("Cancel") { onCancel() }
            }
            .padding()
            .background(.bar)

            Divider()

            List(snapshots.filter { $0.id != excludedSnapshot?.id }) { snapshot in
                Button {
                    onSelect(snapshot)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(snapshot.rootPath)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text(snapshot.date, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(ByteCountFormatter.string(fromByteCount: snapshot.totalSize, countStyle: .file))
                                .font(.headline)
                            Text("\(snapshot.fileCount.formatted()) files")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
        }
        .frame(width: 500, height: 400)
    }
}

struct ScanComparisonView: View {
    let snapshot1: ScanSnapshot
    let snapshot2: ScanSnapshot
    @Environment(\.dismiss) private var dismiss

    private var sizeDiff: Int64 {
        snapshot1.totalSize - snapshot2.totalSize
    }

    private var fileCountDiff: Int {
        snapshot1.fileCount - snapshot2.fileCount
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Scan Comparison")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()
            .background(.bar)

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    comparisonCard

                    categoryComparison

                    topFilesComparison
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }

    private var comparisonCard: some View {
        HStack(spacing: 40) {
            VStack(spacing: 8) {
                Text("Earlier Scan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(snapshot2.date, style: .date)
                    .font(.subheadline)
                Text(ByteCountFormatter.string(fromByteCount: snapshot2.totalSize, countStyle: .file))
                    .font(.title2)
                Text("\(snapshot2.fileCount.formatted()) files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.quaternary)
            .cornerRadius(8)

            VStack(spacing: 8) {
                Image(systemName: sizeDiff > 0 ? "arrow.right" : "arrow.left")
                    .font(.title)
                    .foregroundStyle(sizeDiff > 0 ? .red : .green)

                Text(ByteCountFormatter.string(fromByteCount: abs(sizeDiff), countStyle: .file))
                    .font(.headline)
                    .foregroundStyle(sizeDiff > 0 ? .red : .green)

                Text("\(abs(fileCountDiff)) files \(fileCountDiff > 0 ? "added" : "removed")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text("Later Scan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(snapshot1.date, style: .date)
                    .font(.subheadline)
                Text(ByteCountFormatter.string(fromByteCount: snapshot1.totalSize, countStyle: .file))
                    .font(.title2)
                Text("\(snapshot1.fileCount.formatted()) files")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.quaternary)
            .cornerRadius(8)
        }
    }

    private var categoryComparison: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("By Category")
                .font(.headline)

            let categories1 = Dictionary(uniqueKeysWithValues: snapshot1.categoryBreakdown.map { ($0.category, $0) })
            let categories2 = Dictionary(uniqueKeysWithValues: snapshot2.categoryBreakdown.map { ($0.category, $0) })
            let allCategories = Set(categories1.keys).union(categories2.keys)

            ForEach(Array(allCategories).sorted(), id: \.self) { category in
                let cat1 = categories1[category]
                let cat2 = categories2[category]
                let size1 = cat1?.size ?? 0
                let size2 = cat2?.size ?? 0
                let diff = size1 - size2

                HStack {
                    Text(category)
                        .frame(width: 100, alignment: .leading)

                    Spacer()

                    Text(ByteCountFormatter.string(fromByteCount: size2, countStyle: .file))
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .trailing)

                    Image(systemName: diff > 0 ? "arrow.up" : (diff < 0 ? "arrow.down" : "minus"))
                        .foregroundStyle(diff > 0 ? .red : (diff < 0 ? .green : .secondary))
                        .frame(width: 20)

                    Text(ByteCountFormatter.string(fromByteCount: abs(diff), countStyle: .file))
                        .foregroundStyle(diff > 0 ? .red : (diff < 0 ? .green : .secondary))
                        .frame(width: 80, alignment: .trailing)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(8)
    }

    private var topFilesComparison: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New Largest Files")
                .font(.headline)

            let paths2 = Set(snapshot2.topFiles.map(\.path))
            let newFiles = snapshot1.topFiles.filter { !paths2.contains($0.path) }

            if newFiles.isEmpty {
                Text("No new files in top 100")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(newFiles.prefix(10), id: \.path) { file in
                    HStack {
                        Text(file.name)
                            .lineLimit(1)
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(8)
    }
}
