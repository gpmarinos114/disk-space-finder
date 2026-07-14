import Foundation

struct ScanSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let rootPath: String
    let totalSize: Int64
    let fileCount: Int
    let directoryCount: Int
    let topFiles: [FileSnapshot]
    let categoryBreakdown: [CategorySnapshot]

    struct FileSnapshot: Codable, Hashable {
        let name: String
        let path: String
        let size: Int64
        let fileExtension: String?
    }

    struct CategorySnapshot: Codable, Hashable {
        let category: String
        let size: Int64
        let count: Int
    }

    static func from(node: FileNode) -> ScanSnapshot {
        let allFiles = node.allFiles()
        let topFiles = allFiles
            .sorted { $0.size > $1.size }
            .prefix(100)
            .map { FileSnapshot(name: $0.name, path: $0.path, size: $0.size, fileExtension: $0.fileExtension) }

        var categorySizes: [FileCategory: (size: Int64, count: Int)] = [:]
        for file in allFiles {
            let category = FileCategory.categorize(fileExtension: file.fileExtension)
            let current = categorySizes[category] ?? (0, 0)
            categorySizes[category] = (current.size + file.size, current.count + 1)
        }

        let categoryBreakdown = categorySizes.map { key, value in
            CategorySnapshot(category: key.rawValue, size: value.size, count: value.count)
        }

        return ScanSnapshot(
            id: UUID(),
            date: Date(),
            rootPath: node.path,
            totalSize: node.size,
            fileCount: allFiles.count,
            directoryCount: node.childCount,
            topFiles: Array(topFiles),
            categoryBreakdown: categoryBreakdown
        )
    }
}

class ScanHistoryManager {
    private let saveURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("DiskSpaceFinder", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        saveURL = directory.appendingPathComponent("scan_history.json")
    }

    func save(_ snapshot: ScanSnapshot) {
        var history = loadAll()
        history.append(snapshot)

        if history.count > 50 {
            history = Array(history.suffix(50))
        }

        if let data = try? JSONEncoder().encode(history) {
            try? data.write(to: saveURL)
        }
    }

    func loadAll() -> [ScanSnapshot] {
        guard let data = try? Data(contentsOf: saveURL),
              let history = try? JSONDecoder().decode([ScanSnapshot].self, from: data) else {
            return []
        }
        return history
    }

    func delete(_ snapshot: ScanSnapshot) {
        var history = loadAll()
        history.removeAll { $0.id == snapshot.id }
        if let data = try? JSONEncoder().encode(history) {
            try? data.write(to: saveURL)
        }
    }
}
