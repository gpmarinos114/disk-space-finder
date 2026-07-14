import Foundation

struct CSVExporter {
    static func exportToCSV(node: FileNode) -> String {
        var csv = "Name,Path,Size (Bytes),Type,Modified,Created\n"
        exportNode(node, to: &csv, depth: 0)
        return csv
    }

    private static func exportNode(_ node: FileNode, to csv: inout String, depth: Int) {
        let indent = String(repeating: "  ", count: depth)
        let type = node.isDirectory ? "Folder" : (node.fileExtension?.uppercased() ?? "File")
        let modified = node.modificationDate?.formatted(date: .abbreviated, time: .shortened) ?? ""
        let created = node.creationDate?.formatted(date: .abbreviated, time: .shortened) ?? ""

        let escapedPath = "\"\(node.path.replacingOccurrences(of: "\"", with: "\"\""))\""
        let escapedName = "\"\(node.name.replacingOccurrences(of: "\"", with: "\"\""))\""

        csv += "\(indent)\(escapedName),\(escapedPath),\(node.size),\(type),\(modified),\(created)\n"

        for child in node.children {
            exportNode(child, to: &csv, depth: depth + 1)
        }
    }

    static func exportFlatCSV(node: FileNode) -> String {
        var csv = "Name,Path,Size (Bytes),Size (Human),Type,Modified,Created\n"
        let files = node.allFiles()

        for file in files.sorted(by: { $0.size > $1.size }) {
            let type = file.isDirectory ? "Folder" : (file.fileExtension?.uppercased() ?? "File")
            let modified = file.modificationDate?.formatted(date: .abbreviated, time: .shortened) ?? ""
            let created = file.creationDate?.formatted(date: .abbreviated, time: .shortened) ?? ""
            let escapedPath = "\"\(file.path.replacingOccurrences(of: "\"", with: "\"\""))\""
            let escapedName = "\"\(file.name.replacingOccurrences(of: "\"", with: "\"\""))\""

            csv += "\(escapedName),\(escapedPath),\(file.size),\(file.formattedSize),\(type),\(modified),\(created)\n"
        }

        return csv
    }

    static func saveCSV(content: String, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
