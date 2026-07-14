import SwiftUI

struct TreemapView: View {
    let node: FileNode
    let onNodeSelected: (FileNode) -> Void
    let onDelete: (FileNode) -> Void

    @State private var flashItemIds: Set<UUID> = []
    @State private var previousNodeIds: Set<UUID> = []
    @State private var hoveredItem: FileNode?
    @State private var rightClickedItem: FileNode?
    @State private var showDeleteAlert = false

    init(node: FileNode, onNodeSelected: @escaping (FileNode) -> Void, onDelete: @escaping (FileNode) -> Void = { _ in }) {
        self.node = node
        self.onNodeSelected = onNodeSelected
        self.onDelete = onDelete
    }

    var body: some View {
        GeometryReader { geometry in
            let layoutItems = TreemapLayout.layout(
                items: node.sortedChildren(by: .sizeDescending),
                in: CGRect(origin: .zero, size: geometry.size)
            )

            Canvas { context, size in
                for item in layoutItems {
                    let color = colorForCategory(item.node)
                    let isFlashing = flashItemIds.contains(item.node.id)
                    let isHovered = hoveredItem?.id == item.node.id
                    let rect = item.rect.insetBy(dx: 1, dy: 1)

                    let opacity = isFlashing ? 1.0 : (isHovered ? 0.95 : 0.85)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 4),
                        with: .color(color.opacity(opacity))
                    )

                    if isFlashing {
                        context.fill(
                            Path(roundedRect: rect, cornerRadius: 4),
                            with: .color(.white.opacity(0.3))
                        )
                    }

                    if isHovered {
                        context.stroke(
                            Path(roundedRect: rect, cornerRadius: 4),
                            with: .color(.white.opacity(0.6)),
                            lineWidth: 2
                        )
                    }

                    let minTextWidth: CGFloat = 50
                    let minTextHeight: CGFloat = 24

                    if rect.width >= minTextWidth && rect.height >= minTextHeight {
                        var clippedContext = context
                        clippedContext.clip(to: Path(roundedRect: rect, cornerRadius: 4))

                        let fontSize = min(12, max(9, rect.width / 10))
                        let nameText = Text(truncatedName(item.node.name, maxWidth: rect.width - 12, fontSize: fontSize))
                            .font(.system(size: fontSize, weight: .medium))
                            .foregroundStyle(.white)

                        clippedContext.draw(
                            nameText,
                            at: CGPoint(x: rect.origin.x + 6, y: rect.origin.y + fontSize + 4),
                            anchor: .topLeading
                        )

                        if rect.height >= 40 {
                            let sizeFontSize = min(10, max(8, rect.width / 12))
                            let sizeText = Text(item.node.formattedSize)
                                .font(.system(size: sizeFontSize))
                                .foregroundStyle(.white.opacity(0.85))

                            clippedContext.draw(
                                sizeText,
                                at: CGPoint(x: rect.origin.x + 6, y: rect.origin.y + fontSize + sizeFontSize + 8),
                                anchor: .topLeading
                            )
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .onChange(of: node.children.count) { _, _ in
                updateFlashState(newNode: node)
            }
            .onAppear {
                updateFlashState(newNode: node)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoveredItem = layoutItems.first(where: { $0.rect.contains(location) })?.node
                case .ended:
                    hoveredItem = nil
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let location = value.location
                        if let tapped = layoutItems.first(where: { $0.rect.contains(location) }) {
                            if tapped.node.isDirectory && !tapped.node.children.isEmpty {
                                onNodeSelected(tapped.node)
                            }
                        }
                    }
            )
            .contextMenu {
                if let item = hoveredItem {
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
                        rightClickedItem = item
                        showDeleteAlert = true
                    } label: {
                        Label("Move to Trash", systemImage: "trash")
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .alert("Delete File", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { rightClickedItem = nil }
            Button("Move to Trash", role: .destructive) {
                if let file = rightClickedItem {
                    onDelete(file)
                    rightClickedItem = nil
                }
            }
        } message: {
            if let file = rightClickedItem {
                Text("Are you sure you want to move \"\(file.name)\" to the Trash?")
            }
        }
    }

    private func updateFlashState(newNode: FileNode) {
        let newIds = Set(newNode.children.map(\.id))
        let addedIds = newIds.subtracting(previousNodeIds)

        if !addedIds.isEmpty {
            flashItemIds = addedIds
            withAnimation(.easeOut(duration: 0.6)) {
                flashItemIds = []
            }
        }

        previousNodeIds = newIds
    }

    private func truncatedName(_ name: String, maxWidth: CGFloat, fontSize: CGFloat) -> String {
        let approximateCharWidth = fontSize * 0.6
        let maxChars = Int(maxWidth / approximateCharWidth)

        if name.count <= maxChars {
            return name
        }

        let endIndex = name.index(name.startIndex, offsetBy: max(0, maxChars - 1))
        return String(name[name.startIndex..<endIndex]) + "…"
    }

    private func colorForCategory(_ node: FileNode) -> Color {
        if node.isDirectory {
            return .blue.opacity(0.6)
        }
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

struct TreemapLegendView: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(FileCategory.allCases) { category in
                HStack(spacing: 4) {
                    Circle()
                        .fill(colorForCategory(category))
                        .frame(width: 8, height: 8)
                    Text(category.rawValue)
                        .font(.caption2)
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
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
}
