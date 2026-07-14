import Foundation

enum ScanState: Equatable {
    case idle
    case scanning(path: String, filesScanned: Int)
    case completed(FileNode)
    case error(String)

    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case let (.scanning(lp, lc), .scanning(rp, rc)): return lp == rp && lc == rc
        case (.completed, .completed): return true
        case let (.error(l), .error(r)): return l == r
        default: return false
        }
    }
}

@MainActor
class ScanManager: ObservableObject {
    @Published var scanState: ScanState = .idle
    @Published var rootNode: FileNode?
    @Published var selectedNode: FileNode?
    @Published var navigationPath: [FileNode] = []
    @Published var sortOption: SortOption = .sizeDescending
    @Published var permissionDeniedPaths: [String] = []
    @Published var filesScanned: Int = 0
    @Published var isLoadingChildren = false

    private let scanner = FileScanner()
    private var scanTask: Task<Void, Never>?
    private var isDone = false

    var isScanning: Bool {
        if case .scanning = scanState { return true }
        return false
    }

    func startScan(path: String) {
        scanTask?.cancel()

        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            scanState = .error("Path not found: \(path)")
            return
        }

        scanState = .scanning(path: path, filesScanned: 0)
        rootNode = nil
        selectedNode = nil
        navigationPath = []
        filesScanned = 0
        isDone = false

        let scannerRef = self.scanner

        scanTask = Task { [weak self] in
            guard let self else { return }

            let scanner = scannerRef

            let counterTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if Task.isCancelled { break }

                    let count = await scanner.totalScanned
                    let path = await scanner.getCurrentPath()

                    await MainActor.run { [weak self] in
                        guard let self, !self.isDone else { return }
                        self.filesScanned = count
                        self.scanState = .scanning(path: path, filesScanned: count)
                    }
                }
            }

            do {
                let node = try await scanner.scanDirectory(at: url)
                counterTask.cancel()

                let finalCount = await scanner.totalScanned
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isDone = true
                    self.rootNode = node
                    self.selectedNode = node
                    self.filesScanned = finalCount
                    self.scanState = .completed(node)
                }
            } catch is CancellationError {
                counterTask.cancel()
                await MainActor.run { [weak self] in
                    self?.isDone = true
                    self?.scanState = .idle
                }
            } catch {
                counterTask.cancel()
                await MainActor.run { [weak self] in
                    self?.isDone = true
                    self?.scanState = .error(error.localizedDescription)
                }
            }
        }
    }

    func loadChildren(for node: FileNode) async {
        guard node.isDirectory && !node.childrenLoaded else { return }

        isLoadingChildren = true
        let url = URL(fileURLWithPath: node.path)

        do {
            let children = try await scanner.loadChildren(for: url)
            updateNode(node, with: children)
        } catch {
            // Handle error silently
        }
        isLoadingChildren = false
    }

    private func updateNode(_ target: FileNode, with children: [FileNode]) {
        rootNode = replaceNode(target, in: rootNode, with: children)
        if selectedNode?.id == target.id {
            selectedNode = rootNode?.children.first { $0.id == target.id }
        }
    }

    private func replaceNode(_ target: FileNode, in node: FileNode?, with children: [FileNode]) -> FileNode? {
        guard let node else { return nil }

        if node.id == target.id {
            return FileNode(
                id: node.id,
                name: node.name,
                path: node.path,
                size: node.size,
                children: children,
                isDirectory: node.isDirectory,
                fileExtension: node.fileExtension,
                modificationDate: node.modificationDate,
                creationDate: node.creationDate,
                childrenLoaded: true
            )
        }

        let newChildren = node.children.compactMap { replaceNode(target, in: $0, with: children) }

        return FileNode(
            id: node.id,
            name: node.name,
            path: node.path,
            size: node.size,
            children: newChildren,
            isDirectory: node.isDirectory,
            fileExtension: node.fileExtension,
            modificationDate: node.modificationDate,
            creationDate: node.creationDate,
            childrenLoaded: node.childrenLoaded
        )
    }

    func cancelScan() {
        isDone = true
        scanTask?.cancel()
        Task { await scanner.cancel() }
        scanState = .idle
    }

    func selectNode(_ node: FileNode) {
        selectedNode = node
    }

    func navigateTo(_ node: FileNode) {
        if let root = rootNode {
            navigationPath = buildPath(to: node, from: root)
        }
        selectedNode = node
    }

    func navigateUp() {
        if navigationPath.count > 1 {
            navigationPath.removeLast()
            selectedNode = navigationPath.last
        } else if !navigationPath.isEmpty {
            navigationPath.removeAll()
            selectedNode = rootNode
        }
    }

    func deleteFile(_ node: FileNode) -> Bool {
        let url = URL(fileURLWithPath: node.path)

        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            rootNode = removeNode(node, from: rootNode)
            if selectedNode?.id == node.id {
                selectedNode = rootNode
            }
            return true
        } catch {
            return false
        }
    }

    private func removeNode(_ target: FileNode, from node: FileNode?) -> FileNode? {
        guard let node else { return nil }

        if node.id == target.id {
            return nil
        }

        let newChildren = node.children.compactMap { removeNode(target, from: $0) }
        let newSize = newChildren.reduce(Int64(0)) { $0 + $1.size } + (node.isDirectory ? 0 : node.size)

        return FileNode(
            id: node.id,
            name: node.name,
            path: node.path,
            size: node.isDirectory ? newSize : node.size,
            children: newChildren,
            isDirectory: node.isDirectory,
            fileExtension: node.fileExtension,
            modificationDate: node.modificationDate,
            creationDate: node.creationDate,
            childrenLoaded: node.childrenLoaded
        )
    }

    private func buildPath(to target: FileNode, from current: FileNode) -> [FileNode] {
        if current.id == target.id { return [current] }
        for child in current.children {
            let path = buildPath(to: target, from: child)
            if !path.isEmpty { return [current] + path }
        }
        return []
    }
}
