import Foundation

actor FileScanner {
    private var isCancelled = false
    private var permissionDeniedPaths: [String] = []
    nonisolated(unsafe) var totalScanned: Int = 0
    nonisolated(unsafe) var currentPath: String = ""

    func cancel() {
        isCancelled = true
    }

    func getPermissionDeniedPaths() -> [String] {
        return permissionDeniedPaths
    }

    func scanDirectory(at url: URL) async throws -> FileNode {
        isCancelled = false
        permissionDeniedPaths = []
        totalScanned = 0
        currentPath = url.path
        return try await scan(url: url, depth: 0)
    }

    func loadChildren(for url: URL) async throws -> [FileNode] {
        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey, .isDirectoryKey, .contentModificationDateKey, .creationDateKey, .nameKey
        ]

        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: Array(resourceKeys), options: [.skipsHiddenFiles]
            )
        } catch {
            permissionDeniedPaths.append(url.path)
            return []
        }

        var children: [FileNode] = []

        for childURL in contents {
            if isCancelled { break }

            do {
                let resourceValues = try childURL.resourceValues(forKeys: resourceKeys)
                let name = resourceValues.name ?? childURL.lastPathComponent
                let isDir = resourceValues.isDirectory ?? false
                let size = isDir ? 0 : Int64(resourceValues.fileSize ?? 0)

                let child = FileNode(
                    name: name,
                    path: childURL.path,
                    size: size,
                    isDirectory: isDir,
                    fileExtension: childURL.pathExtension.isEmpty ? nil : childURL.pathExtension,
                    modificationDate: resourceValues.contentModificationDate,
                    creationDate: resourceValues.creationDate,
                    childrenLoaded: false
                )
                children.append(child)
                totalScanned += 1
            } catch {
                permissionDeniedPaths.append(childURL.path)
            }
        }

        return children.sorted { $0.size > $1.size }
    }

    private func scan(url: URL, depth: Int) async throws -> FileNode {
        try Task.checkCancellation()
        if isCancelled { throw ScanError.cancelled }

        currentPath = url.path

        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey, .isDirectoryKey, .contentModificationDateKey, .creationDateKey, .nameKey
        ]

        let resourceValues: URLResourceValues
        do {
            resourceValues = try url.resourceValues(forKeys: resourceKeys)
        } catch {
            permissionDeniedPaths.append(url.path)
            return FileNode(name: url.lastPathComponent, path: url.path, size: 0, isDirectory: false)
        }

        let name = resourceValues.name ?? url.lastPathComponent
        let isDirectory = resourceValues.isDirectory ?? false

        guard isDirectory else {
            totalScanned += 1
            return FileNode(
                name: name, path: url.path, size: Int64(resourceValues.fileSize ?? 0), isDirectory: false,
                fileExtension: url.pathExtension.isEmpty ? nil : url.pathExtension,
                modificationDate: resourceValues.contentModificationDate,
                creationDate: resourceValues.creationDate
            )
        }

        let contents: [URL]
        do {
            contents = try FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: Array(resourceKeys), options: [.skipsHiddenFiles]
            )
        } catch {
            permissionDeniedPaths.append(url.path)
            return FileNode(
                name: name, path: url.path, size: 0, children: [], isDirectory: true,
                modificationDate: resourceValues.contentModificationDate,
                creationDate: resourceValues.creationDate
            )
        }

        var children: [FileNode] = []
        var totalSize: Int64 = 0

        for childURL in contents {
            if isCancelled { throw ScanError.cancelled }

            let child = try await scanItem(url: childURL)
            children.append(child)
            totalSize += child.size
            totalScanned += 1
        }

        for i in children.indices where children[i].isDirectory {
            if isCancelled { throw ScanError.cancelled }
            let scanned = try await scan(url: URL(fileURLWithPath: children[i].path), depth: depth + 1)
            totalSize += scanned.size
            children[i] = scanned
        }

        return FileNode(
            name: name, path: url.path, size: totalSize,
            children: children.sorted { $0.size > $1.size },
            isDirectory: true,
            modificationDate: resourceValues.contentModificationDate,
            creationDate: resourceValues.creationDate
        )
    }

    private func scanItem(url: URL) throws -> FileNode {
        let resourceValues = try url.resourceValues(forKeys: [
            .fileSizeKey, .isDirectoryKey, .contentModificationDateKey, .creationDateKey, .nameKey
        ])
        let name = resourceValues.name ?? url.lastPathComponent
        let isDir = resourceValues.isDirectory ?? false

        return FileNode(
            name: name, path: url.path,
            size: isDir ? 0 : Int64(resourceValues.fileSize ?? 0),
            isDirectory: isDir,
            fileExtension: url.pathExtension.isEmpty ? nil : url.pathExtension,
            modificationDate: resourceValues.contentModificationDate,
            creationDate: resourceValues.creationDate
        )
    }
}

enum ScanError: Error, LocalizedError {
    case cancelled
    case accessDenied(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Scan was cancelled"
        case .accessDenied(let p): return "Access denied: \(p)"
        case .notFound(let p): return "Not found: \(p)"
        }
    }
}
