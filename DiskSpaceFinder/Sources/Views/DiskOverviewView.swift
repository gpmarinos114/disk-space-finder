import SwiftUI

struct DiskOverviewView: View {
    @State private var volumes: [DiskVolume] = []
    @State private var containers: [APFSContainer] = []
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
                        if !containers.isEmpty {
                            containersSection
                        }

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

    private var containersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APFS Containers")
                .font(.headline)
                .padding(.horizontal)

            ForEach(containers) { container in
                ContainerCard(container: container)
            }
        }
    }

    private func loadVolumes() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedVolumes = DiskOverviewService.getVolumes()
            let loadedContainers = DiskOverviewService.getAPFSContainers(volumes: loadedVolumes)
            DispatchQueue.main.async {
                self.volumes = loadedVolumes
                self.containers = loadedContainers
                self.isLoading = false
            }
        }
    }
}

struct ContainerCard: View {
    let container: APFSContainer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "internaldrive")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading) {
                    Text(container.identifier)
                        .font(.headline)
                    Text("\(container.volumes.count) volumes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(ByteCountFormatter.string(fromByteCount: container.usedSpace, countStyle: .file))
                        .font(.headline)
                    Text("of \(ByteCountFormatter.string(fromByteCount: container.totalSpace, countStyle: .file))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(height: 20)

                    HStack(spacing: 1) {
                        ForEach(container.volumes) { volume in
                            let width = max(1, geometry.size.width * CGFloat(volume.totalSpace) / CGFloat(container.totalSpace))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colorForVolume(volume))
                                .frame(width: width, height: 20)
                        }
                    }
                }
            }
            .frame(height: 20)

            HStack {
                Text(String(format: "%.1f%%", container.usagePercentage))
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("\(container.volumes.count) volumes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(container.volumes) { volume in
                HStack {
                    Circle()
                        .fill(colorForVolume(volume))
                        .frame(width: 8, height: 8)
                    Text(volume.name)
                        .font(.caption)
                    Spacer()
                    Text(volume.formattedUsed)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "(%.1f%%)", volume.usagePercentage))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    private func colorForVolume(_ volume: DiskVolume) -> Color {
        switch volume.usagePercentage {
        case 0..<70: return .green
        case 70..<85: return .yellow
        case 85..<95: return .orange
        default: return .red
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
