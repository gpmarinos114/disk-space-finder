import Foundation

enum FileCategory: String, CaseIterable, Identifiable, Codable {
    case documents = "Documents"
    case images = "Images"
    case video = "Video"
    case audio = "Audio"
    case code = "Code"
    case archives = "Archives"
    case applications = "Applications"
    case fonts = "Fonts"
    case other = "Other"

    var id: String { rawValue }

    var extensions: Set<String> {
        switch self {
        case .documents:
            return ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "csv", "pages", "numbers", "keynote", "md", "json", "xml", "html"]
        case .images:
            return ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "webp", "heic", "heif", "svg", "ico", "psd", "ai", "raw", "cr2", "nef"]
        case .video:
            return ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v", "mpg", "mpeg", "3gp"]
        case .audio:
            return ["mp3", "wav", "aac", "flac", "ogg", "wma", "m4a", "aiff", "alac"]
        case .code:
            return ["swift", "py", "js", "ts", "jsx", "tsx", "java", "c", "cpp", "h", "hpp", "cs", "rb", "go", "rs", "php", "html", "css", "scss", "json", "xml", "yaml", "yml", "toml", "sh", "bash", "sql"]
        case .archives:
            return ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "dmg", "iso", "tgz"]
        case .applications:
            return ["app", "ipa", "apk"]
        case .fonts:
            return ["ttf", "otf", "woff", "woff2", "eot"]
        case .other:
            return []
        }
    }

    static func categorize(fileExtension: String?) -> FileCategory {
        guard let ext = fileExtension?.lowercased() else { return .other }
        for category in FileCategory.allCases where category != .other {
            if category.extensions.contains(ext) {
                return category
            }
        }
        return .other
    }
}
