import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Binding var selection: AppSection?

    @State private var disk: DiskOverview?

    private let quickAccessSections: [AppSection] = [.smartClean, .cacheCleaner, .archScanner, .duplicateFinder, .largeFiles, .uninstaller, .loginItems, .updateManager]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                diskUsageCard
                freedSpaceCard
                quickAccessGrid
            }
            .padding()
        }
        .navigationTitle(settings.t(AppSection.dashboard.titleKey))
        .onAppear { disk = DiskOverview.current() }
    }

    @ViewBuilder
    private var diskUsageCard: some View {
        if let disk {
            VStack(alignment: .leading, spacing: 8) {
                Text(settings.t("dashboard.disk_usage"))
                    .font(.headline)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(settings.accentTheme.color)
                            .frame(width: geo.size.width * disk.usedFraction)
                    }
                }
                .frame(height: 14)

                HStack {
                    Text("\(settings.t("dashboard.used")): \(disk.usedBytes.formattedFileSize)")
                    Spacer()
                    Text("\(settings.t("dashboard.free")): \(disk.freeBytes.formattedFileSize)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var freedSpaceCard: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(settings.accentTheme.color)
            VStack(alignment: .leading) {
                Text(settings.t("dashboard.total_freed"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(stats.totalBytesFreed.formattedFileSize)
                    .font(.title2).bold()
            }
            Spacer()
        }
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    private var quickAccessGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(settings.t("dashboard.quick_access"))
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(quickAccessSections) { section in
                    Button {
                        selection = section
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: section.systemImage)
                                .font(.title2)
                                .foregroundStyle(settings.accentTheme.color)
                            Text(settings.t(section.titleKey))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
