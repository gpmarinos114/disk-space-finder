import SwiftUI

struct DiskOverviewView: View {
    @State private var volumes: [DiskVolume] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Disk Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Refresh") {
                    loadVolumes()
                }
            }
            .padding()
            .background(.bar)

            Divider()

            if isLoading {
                ProgressView("Loading volumes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if volumes.isEmpty {
                ContentUnavailableView(
                    "No Volumes Found",
                    systemImage: "externaldrive.badge.questionmark"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(volumes) { volume in
                            VolumeCard(volume: volume)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadVolumes()
        }
    }

    private func loadVolumes() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedVolumes = DiskOverviewService.getVolumes()
            DispatchQueue.main.async {
                self.volumes = loadedVolumes
                self.isLoading = false
            }
        }
    }
}

struct VolumeCard: View {
    let volume: DiskVolume

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: volume.isRemovable ? "externaldrive" : "internaldrive")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading) {
                    Text(volume.name)
                        .font(.headline)
                    Text(volume.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(volume.filesystemType)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .cornerRadius(4)
                    if volume.isRemovable {
                        Text("Removable")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Used: \(volume.formattedUsed)")
                    Spacer()
                    Text("Available: \(volume.formattedAvailable)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.quaternary)
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(usageColor)
                            .frame(width: geometry.size.width * volume.usagePercentage / 100, height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text(String(format: "%.1f%%", volume.usagePercentage))
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("Total: \(volume.formattedTotal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if volume.purgeableSpace > 0 {
                HStack {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                    Text("Purgeable: \(volume.formattedPurgeable)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private var usageColor: Color {
        switch volume.usagePercentage {
        case 0..<70: return .green
        case 70..<85: return .yellow
        case 85..<95: return .orange
        default: return .red
        }
    }
}
