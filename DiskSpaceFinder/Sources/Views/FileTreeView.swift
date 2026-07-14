import SwiftUI

struct FileTreeView: View {
    let node: FileNode
    @Binding var selectedNode: FileNode?
    @Binding var sortOption: SortOption

    @State private var expandedNodes: Set<UUID> = []
    @State private var searchText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Sort", selection: $sortOption) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)

                Spacer()

                Text(node.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            List(selection: $selectedNode) {
                if searchText.isEmpty {
                    ForEach(node.sortedChildren(by: sortOption)) { child in
                        fileRow(node: child, depth: 0)
                    }
                } else {
                    ForEach(filteredNodes) { child in
                        fileRow(node: child, depth: 0)
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $searchText, prompt: "Filter files...")
        }
    }

    private var filteredNodes: [FileNode] {
        guard !searchText.isEmpty else { return node.sortedChildren(by: sortOption) }
        return node.sortedChildren(by: sortOption).filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    @ViewBuilder
    private func fileRow(node: FileNode, depth: Int) -> some View {
        HStack {
            if node.isDirectory {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
                    .frame(width: 16)
            } else {
                Image(systemName: iconForFile(node))
                    .foregroundStyle(colorForFile(node))
                    .frame(width: 16)
            }

            Text(node.name)
                .fontWeight(node.isDirectory ? .medium : .regular)
                .lineLimit(1)

            Spacer()

            if node.isDirectory {
                Text("\(node.childCount) items")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if let ext = node.fileExtension {
                Text(ext.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.quaternary)
                    .cornerRadius(3)
            }

            Text(node.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.vertical, 2)
        .padding(.leading, CGFloat(depth) * 16)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedNode = node
        }
        .tag(node)
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
