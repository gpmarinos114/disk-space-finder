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

    private let scanner = FileScanner()
    private var scanTask: Task<Void, Never>?

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

        let scannerRef = self.scanner

        scanTask = Task { [weak self] in
            guard let self else { return }

            let counterTask = Task { [weak self] in
                let scanner = scannerRef
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    if Task.isCancelled { break }
                    let count = await scanner.totalScanned
                    let currentPath = await scanner.getCurrentPath()
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.filesScanned = count
                        self.scanState = .scanning(path: currentPath, filesScanned: count)
                    }
                }
            }

            do {
                let node = try await scannerRef.scanDirectory(at: url)
                counterTask.cancel()

                if !Task.isCancelled {
                    self.rootNode = node
                    self.selectedNode = node
                    self.filesScanned = await scannerRef.totalScanned
                    self.scanState = .completed(node)
                    self.permissionDeniedPaths = await scannerRef.getPermissionDeniedPaths()
                }
            } catch is CancellationError {
                counterTask.cancel()
                self.scanState = .idle
            } catch {
                counterTask.cancel()
                self.scanState = .error(error.localizedDescription)
            }
        }
    }

    func cancelScan() {
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
            creationDate: node.creationDate
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
