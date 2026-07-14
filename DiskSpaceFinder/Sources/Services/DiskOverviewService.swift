import Foundation

struct DiskVolume: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let totalSpace: Int64
    let usedSpace: Int64
    let availableSpace: Int64
    let purgeableSpace: Int64
    let isRemovable: Bool
    let isInternal: Bool
    let filesystemType: String

    var usagePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace) * 100
    }

    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
    }

    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
    }

    var formattedAvailable: String {
        ByteCountFormatter.string(fromByteCount: availableSpace, countStyle: .file)
    }

    var formattedPurgeable: String {
        ByteCountFormatter.string(fromByteCount: purgeableSpace, countStyle: .file)
    }
}

class DiskOverviewService {
    static func getVolumes() -> [DiskVolume] {
        var volumes: [DiskVolume] = []

        let keys: Set<URLResourceKey> = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeIsRemovableKey,
            .volumeIsInternalKey
        ]

        let volumeURLs = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: Array(keys),
            options: [.skipHiddenVolumes]
        ) ?? []

        for url in volumeURLs {
            guard let resourceValues = try? url.resourceValues(forKeys: keys) else { continue }

            let name = resourceValues.volumeName ?? url.lastPathComponent
            let total = Int64(resourceValues.volumeTotalCapacity ?? 0)
            let available = Int64(resourceValues.volumeAvailableCapacity ?? 0)
            let purgeable = Int64(resourceValues.volumeAvailableCapacityForImportantUsage ?? 0)
            let isRemovable = resourceValues.volumeIsRemovable ?? false
            let isInternal = resourceValues.volumeIsInternal ?? true
            let used = total - available

            let filesystemType = getFileSystemType(for: url.path)

            let volume = DiskVolume(
                name: name,
                path: url.path,
                totalSpace: total,
                usedSpace: used,
                availableSpace: available,
                purgeableSpace: purgeable,
                isRemovable: isRemovable,
                isInternal: isInternal,
                filesystemType: filesystemType
            )
            volumes.append(volume)
        }

        return volumes.sorted { $0.totalSpace > $1.totalSpace }
    }

    private static func getFileSystemType(for path: String) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        task.arguments = ["info", "-plist", path]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
               let fsType = plist["FilesystemType"] as? String {
                return fsType
            }
        } catch {}

        return "Unknown"
    }
}
