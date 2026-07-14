import SwiftUI

struct ContentView: View {
    @EnvironmentObject var scanManager: ScanManager
    @State private var showingFolderPicker = false
    @State private var selectedVisualization: VisualizationType = .treemap
    @State private var scanPath: String = ""

    enum VisualizationType: String, CaseIterable {
        case treemap = "Treemap"
        case sunburst = "Sunburst"
        case tree = "Tree"
        case charts = "Charts"
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showingFolderPicker = true }) {
                    Label("Scan Folder", systemImage: "folder.badge.plus")
                }
            }

            ToolbarItem(placement: .automatic) {
                if scanManager.isScanning {
                    Button(action: { scanManager.cancelScan() }) {
                        Label("Cancel", systemImage: "xmark.circle.fill")
                    }
                }
            }

            ToolbarItem(placement: .principal) {
                Picker("View", selection: $selectedVisualization) {
                    ForEach(VisualizationType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
        }
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                scanPath = url.path
                scanManager.startScan(path: url.path)
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            scanPathHeader
            Divider()

            switch scanManager.scanState {
            case .idle:
                idleView
            case .scanning(let path, let count):
                scanningView(path: path, count: count)
            case .completed:
                if let root = scanManager.rootNode {
                    FileTreeView(
                        node: root,
                        selectedNode: $scanManager.selectedNode,
                        sortOption: $scanManager.sortOption
                    )
                }
            case .error(let message):
                errorView(message)
            }
        }
        .frame(minWidth: 250, idealWidth: 300)
    }

    private var scanPathHeader: some View {
        HStack {
            if !scanPath.isEmpty {
                Label(scanPath, systemImage: "externaldrive")
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Label("No folder selected", systemImage: "externaldrive")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var idleView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "externaldrive.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Select a folder to scan")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("Choose Folder") {
                showingFolderPicker = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func scanningView(path: String, count: Int) -> some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .frame(width: 20, height: 20)
            Text("Scanning...")
                .font(.headline)
            Text(path)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 200)
            Text("\(count.formatted()) items scanned")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Button("Cancel") {
                scanManager.cancelScan()
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Scan Error")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try Again") {
                showingFolderPicker = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var detailView: some View {
        if let _ = scanManager.rootNode, let selected = scanManager.selectedNode {
            VStack(spacing: 0) {
                BreadcrumbView(
                    path: scanManager.navigationPath,
                    onNavigate: { node in
                        scanManager.navigateTo(node)
                    },
                    onNavigateUp: {
                        scanManager.navigateUp()
                    }
                )
                Divider()

                Group {
                    if scanManager.isLoadingChildren {
                        VStack(spacing: 16) {
                            Spacer()
                            ProgressView()
                                .frame(width: 20, height: 20)
                            Text("Loading folder contents...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        switch selectedVisualization {
                        case .treemap:
                            TreemapView(
                                node: selected,
                                onNodeSelected: { node in
                                    if !node.childrenLoaded {
                                        Task { await scanManager.loadChildren(for: node) }
                                    }
                                    scanManager.navigateTo(node)
                                },
                                onDelete: { _ = scanManager.deleteFile($0) }
                            )
                        case .sunburst:
                            SunburstView(node: selected, onNodeSelected: { node in
                                if !node.childrenLoaded {
                                    Task { await scanManager.loadChildren(for: node) }
                                }
                                scanManager.navigateTo(node)
                            })
                        case .tree:
                            TreeDetailView(
                                node: selected,
                                sortOption: $scanManager.sortOption,
                                onNodeSelected: { node in
                                    if !node.childrenLoaded {
                                        Task { await scanManager.loadChildren(for: node) }
                                    }
                                    scanManager.navigateTo(node)
                                },
                                onDelete: { _ = scanManager.deleteFile($0) }
                            )
                        case .charts:
                            ChartsView(
                                node: selected,
                                onNodeSelected: { node in
                                    if !node.childrenLoaded {
                                        Task { await scanManager.loadChildren(for: node) }
                                    }
                                    scanManager.navigateTo(node)
                                },
                                onDelete: { _ = scanManager.deleteFile($0) }
                            )
                        }
                    }
                }
                .clipped()
            }
        } else {
            ContentUnavailableView(
                "No Scan Results",
                systemImage: "doc.text.magnifyingglass",
                description: Text("Select a folder to begin scanning")
            )
        }
    }
}

struct BreadcrumbView: View {
    let path: [FileNode]
    let onNavigate: (FileNode) -> Void
    let onNavigateUp: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            if !path.isEmpty {
                Button(action: onNavigateUp) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)

                ForEach(Array(path.enumerated()), id: \.element.id) { index, node in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Button(node.name) {
                        onNavigate(node)
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.bar)
    }
}
