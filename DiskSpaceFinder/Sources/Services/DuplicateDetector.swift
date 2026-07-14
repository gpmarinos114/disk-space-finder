import Foundation
import CryptoKit

actor DuplicateDetector {
    struct DuplicateGroup: Identifiable, Sendable {
        let id = UUID()
        let hash: String
        let size: Int64
        var files: [FileNode]
        var wastedSpace: Int64 {
            size * Int64(max(0, files.count - 1))
        }
    }

    func findDuplicates(in node: FileNode) async -> [DuplicateGroup] {
        var sizeMap: [Int64: [FileNode]] = [:]
        collectFiles(node, into: &sizeMap)

        let candidates = sizeMap.filter { $0.value.count > 1 }

        var hashGroups: [String: [FileNode]] = [:]

        for (_, files) in candidates {
            for file in files {
                if let hash = try? await hashFile(at: file.path) {
                    hashGroups[hash, default: []].append(file)
                }
            }
        }

        return hashGroups
            .filter { $0.value.count > 1 }
            .map { hash, files in
                DuplicateGroup(
                    hash: hash,
                    size: files.first?.size ?? 0,
                    files: files
                )
            }
            .sorted { $0.wastedSpace > $1.wastedSpace }
    }

    func findQuickDuplicates(in node: FileNode) -> [DuplicateGroup] {
        var sizeNameMap: [String: [FileNode]] = [:]
        collectFilesForQuickScan(node, into: &sizeNameMap)

        return sizeNameMap
            .filter { $0.value.count > 1 }
            .map { key, files in
                DuplicateGroup(
                    hash: key,
                    size: files.first?.size ?? 0,
                    files: files
                )
            }
            .sorted { $0.wastedSpace > $1.wastedSpace }
    }

    private func collectFiles(_ node: FileNode, into map: inout [Int64: [FileNode]]) {
        if !node.isDirectory && node.size > 0 {
            map[node.size, default: []].append(node)
        }
        for child in node.children {
            collectFiles(child, into: &map)
        }
    }

    private func collectFilesForQuickScan(_ node: FileNode, into map: inout [String: [FileNode]]) {
        if !node.isDirectory {
            let key = "\(node.size)_\(node.name)"
            map[key, default: []].append(node)
        }
        for child in node.children {
            collectFilesForQuickScan(child, into: &map)
        }
    }

    private func hashFile(at path: String) async throws -> String {
        let url = URL(fileURLWithPath: path)
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        let chunkSize = 65536

        while autoreleasepool(invoking: {
            let data = try? handle.read(upToCount: chunkSize)
            if let data, !data.isEmpty {
                hasher.update(data: data)
                return true
            }
            return false
        }) {}

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
