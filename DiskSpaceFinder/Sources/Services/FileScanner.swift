import Foundation

actor FileScanner {
    private var isCancelled = false
    private var permissionDeniedPaths: [String] = []
    private(set) var totalScanned = 0
    private(set) var currentPath: String = ""

    private static let skipDirectories: Set<String> = [
        ".git", ".svn", ".hg",
        "node_modules", ".npm", ".yarn",
        ".cache", "Caches", ".Trash",
        "Library/Caches", "Library/Logs",
        ".DS_Store", ".fseventsd",
        ".Spotlight-V100", ".TemporaryItems",
        ".vol", ".vol.icloud"
    ]

    private static let skipPaths: Set<String> = [
        "/dev", "/System/Volumes", "/private/var/vm",
        "/Library/Developer", "/Library/Caches",
        "/System/Library/Caches"
    ]

    func cancel() {
        isCancelled = true
    }

    func getPermissionDeniedPaths() -> [String] {
        return permissionDeniedPaths
    }

    func getCurrentPath() -> String {
        return currentPath
    }

    func scanDirectory(at url: URL) async throws -> FileNode {
        isCancelled = false
        permissionDeniedPaths = []
        totalScanned = 0
        currentPath = url.path
        return try await scan(url: url, depth: 0)
    }

    private func shouldSkip(_ url: URL) -> Bool {
        let path = url.path
        let name = url.lastPathComponent

        if Self.skipDirectories.contains(name) {
            return true
        }

        for skipPath in Self.skipPaths {
            if path.hasPrefix(skipPath) {
                return true
            }
        }

        return false
    }

    private func scan(url: URL, depth: Int) async throws -> FileNode {
        try Task.checkCancellation()
        if isCancelled { throw ScanError.cancelled }

        if depth > 0 && shouldSkip(url) {
            return FileNode(name: url.lastPathComponent, path: url.path, size: 0, isDirectory: true)
        }

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
