import Foundation

struct CompressService {
    static func compressFolder(at url: URL) throws -> URL {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let zipURL = tempDir.appendingPathComponent(url.lastPathComponent + ".zip")

        if fileManager.fileExists(atPath: zipURL.path) {
            try fileManager.removeItem(at: zipURL)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", zipURL.path, url.lastPathComponent]
        process.currentDirectoryURL = url.deletingLastPathComponent()

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw CompressError.compressionFailed
        }

        return zipURL
    }

    enum CompressError: LocalizedError {
        case compressionFailed

        var errorDescription: String? {
            switch self {
            case .compressionFailed:
                return "Failed to compress the folder"
            }
        }
    }
}
