import SwiftUI

struct FilePreviewView: View {
    let file: FileNode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(file.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()
            .background(.bar)

            Divider()

            VStack(spacing: 16) {
                Spacer()

                Image(systemName: iconForFile)
                    .font(.system(size: 48))
                    .foregroundStyle(colorForFile)

                Text(file.name)
                    .font(.title3)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(file.formattedSize)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if let ext = file.fileExtension {
                    Text(ext.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .cornerRadius(6)
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
                .padding(.top, 8)

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
