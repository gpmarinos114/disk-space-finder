import Foundation

struct FileNode: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let size: Int64
    var children: [FileNode]
    let isDirectory: Bool
    let fileExtension: String?
    let modificationDate: Date?
    let creationDate: Date?
    let childrenLoaded: Bool

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        size: Int64,
        children: [FileNode] = [],
        isDirectory: Bool,
        fileExtension: String? = nil,
        modificationDate: Date? = nil,
        creationDate: Date? = nil,
        childrenLoaded: Bool = true
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.children = children
        self.isDirectory = isDirectory
        self.fileExtension = fileExtension
        self.modificationDate = modificationDate
        self.creationDate = creationDate
        self.childrenLoaded = childrenLoaded
    }
}

extension FileNode {
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var childCount: Int {
        if isDirectory {
            return children.reduce(0) { $0 + ($1.isDirectory ? $1.childCount + 1 : 1) }
        }
        return 0
    }

    func sortedChildren(by option: SortOption) -> [FileNode] {
        switch option {
        case .sizeDescending:
            return children.sorted { $0.size > $1.size }
        case .sizeAscending:
            return children.sorted { $0.size < $1.size }
        case .nameAscending:
            return children.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            return children.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .dateModified:
            return children.sorted { ($0.modificationDate ?? .distantPast) > ($1.modificationDate ?? .distantPast) }
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case sizeDescending = "Size (Largest)"
    case sizeAscending = "Size (Smallest)"
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case dateModified = "Date Modified"

    var id: String { rawValue }
}
