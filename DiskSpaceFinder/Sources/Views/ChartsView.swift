import SwiftUI
import Charts

struct ChartsView: View {
    let node: FileNode
    let onNodeSelected: (FileNode) -> Void
    let onDelete: (FileNode) -> Void

    @State private var selectedChart: ChartType = .topFiles
    @State private var fileToDelete: FileNode?

    init(
        node: FileNode,
        onNodeSelected: @escaping (FileNode) -> Void = { _ in },
        onDelete: @escaping (FileNode) -> Void = { _ in }
    ) {
        self.node = node
        self.onNodeSelected = onNodeSelected
        self.onDelete = onDelete
    }

    enum ChartType: String, CaseIterable {
        case topFiles = "Top Files"
        case fileTypes = "File Types"
        case sizeDistribution = "Size Distribution"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Chart", selection: $selectedChart) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            GeometryReader { geometry in
                switch selectedChart {
                case .topFiles:
                    topFilesChart(availableHeight: geometry.size.height)
                case .fileTypes:
                    fileTypesChart(availableHeight: geometry.size.height)
                case .sizeDistribution:
                    sizeDistributionChart(availableHeight: geometry.size.height)
                }
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

    private func topFilesChart(availableHeight: CGFloat) -> some View {
        let topItems = Array(node.sortedChildren(by: .sizeDescending).prefix(10))

        return VStack(alignment: .leading, spacing: 0) {
            Text("Top 10 Largest Items")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 8)

            Chart(topItems, id: \.id) { item in
                BarMark(
                    x: .value("Size", item.size),
                    y: .value("Name", item.name)
                )
                .foregroundStyle(colorForItem(item).gradient)
                .annotation(position: .trailing) {
                    Text(item.formattedSize)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        Text(ByteCountFormatter.string(
                            fromByteCount: Int64(value.as(Int.self) ?? 0),
                            countStyle: .file
                        ))
                    }
                }
            }
            .frame(height: max(100, availableHeight * 0.4))
            .padding(.horizontal)

            Divider()
                .padding(.vertical, 8)

            List(topItems) { item in
                HStack {
                    Image(systemName: item.isDirectory ? "folder.fill" : "doc")
                        .foregroundStyle(item.isDirectory ? .blue : .gray)
                        .frame(width: 16)

                    Text(item.name)
                        .lineLimit(1)

                    Spacer()

                    Text(item.formattedSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if item.isDirectory {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if item.isDirectory && !item.children.isEmpty {
                        onNodeSelected(item)
                    }
                }
                .contextMenu {
                    Button {
                        if item.isDirectory {
                            onNodeSelected(item)
                        }
                    } label: {
                        Label("Open", systemImage: "arrow.right")
                    }

                    Button {
                        NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(item.path, forType: .string)
                    } label: {
                        Label("Copy Path", systemImage: "doc.on.doc")
                    }

                    if item.isDirectory {
                        Button {
                            compressFolder(item)
                        } label: {
                            Label("Compress", systemImage: "archivebox")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        fileToDelete = item
                    } label: {
                        Label("Move to Trash", systemImage: "trash")
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func fileTypesChart(availableHeight: CGFloat) -> some View {
        let typeBreakdown = calculateTypeBreakdown()
        let chartSize = min(availableHeight - 80, 250)

        return VStack(alignment: .leading, spacing: 0) {
            Text("File Type Distribution")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 8)

            HStack {
                Chart(typeBreakdown, id: \.category) { item in
                    SectorMark(
                        angle: .value("Size", item.size),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(colorForCategory(item.category))
                    .annotation(position: .overlay) {
                        if item.percentage > 5 {
                            Text(item.category.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(width: chartSize, height: chartSize)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(typeBreakdown, id: \.category) { item in
                        HStack {
                            Circle()
                                .fill(colorForCategory(item.category))
                                .frame(width: 10, height: 10)
                            Text(item.category.rawValue)
                                .font(.caption)
                            Spacer()
                            Text(ByteCountFormatter.string(
                                fromByteCount: item.size,
                                countStyle: .file
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Text(String(format: "(%.1f%%)", item.percentage))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }

    private func sizeDistributionChart(availableHeight: CGFloat) -> some View {
        let distribution = calculateSizeDistribution()

        return VStack(alignment: .leading) {
            Text("Size Distribution")
                .font(.headline)
                .padding(.horizontal)

            Chart(distribution, id: \.range) { item in
                BarMark(
                    x: .value("Range", item.range),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(.blue.gradient)
                .annotation(position: .top) {
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: availableHeight - 50)
            .padding()
        }
    }

    private struct TypeBreakdownItem {
        let category: FileCategory
        let size: Int64
        let percentage: Double
    }

    private struct SizeDistributionItem {
        let range: String
        let count: Int
    }

    private func calculateTypeBreakdown() -> [TypeBreakdownItem] {
        var sizes: [FileCategory: Int64] = [:]

        func collect(_ node: FileNode) {
            if !node.isDirectory {
                let category = FileCategory.categorize(fileExtension: node.fileExtension)
                sizes[category, default: 0] += node.size
            }
            for child in node.children {
                collect(child)
            }
        }
        collect(node)

        let total = sizes.values.reduce(0, +)
        return sizes
            .sorted { $0.value > $1.value }
            .map { TypeBreakdownItem(
                category: $0.key,
                size: $0.value,
                percentage: total > 0 ? Double($0.value) / Double(total) * 100 : 0
            ) }
    }

    private func calculateSizeDistribution() -> [SizeDistributionItem] {
        var counts: [String: Int] = [
            "0-1KB": 0, "1-10KB": 0, "10-100KB": 0, "100KB-1MB": 0,
            "1-10MB": 0, "10-100MB": 0, "100MB-1GB": 0, "1GB+": 0
        ]

        func collect(_ node: FileNode) {
            if !node.isDirectory {
                let size = node.size
                switch size {
                case 0..<1024: counts["0-1KB", default: 0] += 1
                case 1024..<10240: counts["1-10KB", default: 0] += 1
                case 10240..<102400: counts["10-100KB", default: 0] += 1
                case 102400..<1048576: counts["100KB-1MB", default: 0] += 1
                case 1048576..<10485760: counts["1-10MB", default: 0] += 1
                case 10485760..<104857600: counts["10-100MB", default: 0] += 1
                case 104857600..<1073741824: counts["100MB-1GB", default: 0] += 1
                default: counts["1GB+", default: 0] += 1
                }
            }
            for child in node.children {
                collect(child)
            }
        }
        collect(node)

        let order = ["0-1KB", "1-10KB", "10-100KB", "100KB-1MB", "1-10MB", "10-100MB", "100MB-1GB", "1GB+"]
        return order.map { SizeDistributionItem(range: $0, count: counts[$0] ?? 0) }
    }

    private func colorForItem(_ node: FileNode) -> Color {
        let category = FileCategory.categorize(fileExtension: node.fileExtension)
        return colorForCategory(category)
    }

    private func colorForCategory(_ category: FileCategory) -> Color {
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

    private func compressFolder(_ node: FileNode) {
        let url = URL(fileURLWithPath: node.path)
        Task {
            do {
                let zipURL = try CompressService.compressFolder(at: url)
                NSWorkspace.shared.selectFile(zipURL.path, inFileViewerRootedAtPath: "")
            } catch {
                // Handle error
            }
        }
    }
}
