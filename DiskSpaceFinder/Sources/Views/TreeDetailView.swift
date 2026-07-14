import SwiftUI

struct TreeDetailView: View {
    let node: FileNode
    @Binding var sortOption: SortOption
    let onNodeSelected: (FileNode) -> Void
    let onDelete: (FileNode) -> Void

    @State private var selectedChild: FileNode?
    @State private var fileToDelete: FileNode?
    @State private var fileToPreview: FileNode?

    init(
        node: FileNode,
        sortOption: Binding<SortOption>,
        onNodeSelected: @escaping (FileNode) -> Void = { _ in },
        onDelete: @escaping (FileNode) -> Void = { _ in }
    ) {
        self.node = node
        self._sortOption = sortOption
        self.onNodeSelected = onNodeSelected
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            contentArea
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
            if let file = fileToDelete {
                Text("Are you sure you want to move \"\(file.name)\" to the Trash?")
            }
        }
        .sheet(item: $fileToPreview) { file in
            VStack(spacing: 0) {
                FilePreviewView(file: file)
            }
            .frame(width: 450, height: 350)
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(node.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(node.formattedSize)
                    .font(.title3)
                    .fontWeight(.semibold)
                if node.isDirectory {
                    Text("\(node.childCount) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.bar)
    }

    private var contentArea: some View {
        List(node.sortedChildren(by: sortOption), selection: $selectedChild) { child in
            row(for: child)
                .contentShape(Rectangle())
                .onTapGesture {
                    if child.isDirectory && !child.children.isEmpty {
                        onNodeSelected(child)
                    } else if !child.isDirectory {
                        fileToPreview = child
                    }
                }
                .contextMenu {
                    Button {
                        if child.isDirectory {
                            onNodeSelected(child)
                        } else {
                            NSWorkspace.shared.open(URL(fileURLWithPath: child.path))
                        }
                    } label: {
                        Label("Open", systemImage: "arrow.right")
                    }

                    Button {
                        NSWorkspace.shared.selectFile(child.path, inFileViewerRootedAtPath: "")
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(child.path, forType: .string)
                    } label: {
                        Label("Copy Path", systemImage: "doc.on.doc")
                    }

                    if child.isDirectory {
                        Button {
                            compressFolder(child)
                        } label: {
                            Label("Compress", systemImage: "archivebox")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        fileToDelete = child
                    } label: {
                        Label("Move to Trash", systemImage: "trash")
                    }
                }
                .tag(child)
        }
        .listStyle(.inset)
    }

    private func row(for child: FileNode) -> some View {
        HStack {
            Image(systemName: child.isDirectory ? "folder.fill" : "doc")
                .foregroundStyle(child.isDirectory ? .blue : .gray)
                .frame(width: 16)

            Text(child.name)
                .lineLimit(1)

            Spacer()

            if child.isDirectory {
                Text("\(child.childCount) items")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else if let ext = child.fileExtension {
                Text(ext.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.quaternary)
                    .cornerRadius(3)
            }

            Text(child.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 60, alignment: .trailing)

            let percentage = node.size > 0 ? Double(child.size) / Double(node.size) * 100 : 0
            ProgressView(value: percentage / 100)
                .frame(width: 60)
            Text(String(format: "%.1f%%", percentage))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
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
