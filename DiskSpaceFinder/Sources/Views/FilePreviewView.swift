import SwiftUI
import QuickLook

struct FilePreviewView: View {
    let file: FileNode

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: iconForFile)
                .font(.system(size: 64))
                .foregroundStyle(colorForFile)

            Text(file.name)
                .font(.title2)
                .fontWeight(.medium)

            Text(file.formattedSize)
                .font(.title3)
                .foregroundStyle(.secondary)

            if let ext = file.fileExtension {
                Text(ext.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .cornerRadius(4)
            }

            if let date = file.modificationDate {
                Text("Modified \(date, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Button("Open") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
                }
                .buttonStyle(.borderedProminent)

                Button("Show in Finder") {
                    NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var iconForFile: String {
        let category = FileCategory.categorize(fileExtension: file.fileExtension)
        switch category {
        case .documents: return "doc.text"
        case .images: return "photo"
        case .video: return "video"
        case .audio: return "music.note"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .archives: return "archivebox"
        case .applications: return "app"
        case .fonts: return "textformat"
        case .other: return "doc"
        }
    }

    private var colorForFile: Color {
        let category = FileCategory.categorize(fileExtension: file.fileExtension)
        switch category {
        case .documents: return .blue
        case .images: return .green
        case .video: return .purple
        case .audio: return .orange
        case .code: return .cyan
        case .archives: return .brown
        case .applications: return .red
        case .fonts: return .pink
        case .other: return .gray
        }
    }
}
