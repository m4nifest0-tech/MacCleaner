import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Binding var selection: AppSection?

    @State private var disk: DiskOverview?
    @State private var reportPreviewURL: URL?
    @State private var showReportPreview = false
    @State private var exportBanner: String?

    private let quickAccessSections: [AppSection] = [.smartClean, .cacheCleaner, .archScanner, .duplicateFinder, .largeFiles, .diskExplorer, .mailAttachments, .uninstaller, .loginItems, .updateManager]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let exportBanner {
                    exportBannerView(exportBanner)
                }
                diskUsageCard
                freedSpaceCard
                quickAccessGrid
            }
            .padding()
        }
        .navigationTitle(settings.t(AppSection.dashboard.titleKey))
        .onAppear { disk = DiskOverview.current() }
        .sheet(isPresented: $showReportPreview) {
            if let reportPreviewURL {
                ReportPreviewSheet(tempURL: reportPreviewURL) { _ in
                    exportBanner = settings.t("report.export_success")
                    Task {
                        try? await Task.sleep(for: .seconds(4))
                        exportBanner = nil
                    }
                }
            }
        }
    }

    private func exportBannerView(_ message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
            Spacer()
            Button {
                exportBanner = nil
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
        }
        .padding(10)
        .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var diskUsageCard: some View {
        if let disk {
            HStack(spacing: 24) {
                diskUsageGauge(disk)

                VStack(alignment: .leading, spacing: 10) {
                    Text(settings.t("dashboard.disk_usage"))
                        .font(.headline)

                    HStack(spacing: 6) {
                        Circle().fill(settings.accentTheme.color).frame(width: 8, height: 8)
                        Text("\(settings.t("dashboard.used")): \(disk.usedBytes.formattedFileSize)")
                    }
                    HStack(spacing: 6) {
                        Circle().fill(Color.gray.opacity(0.35)).frame(width: 8, height: 8)
                        Text("\(settings.t("dashboard.free")): \(disk.freeBytes.formattedFileSize)")
                    }
                }
                .font(.callout)

                Spacer()
            }
            .padding()
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    /// Anello di avanzamento invece della barra rettangolare: meno "squadrato", con
    /// estremità arrotondate e la percentuale al centro.
    private func diskUsageGauge(_ disk: DiskOverview) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(disk.usedFraction, 0.015))
                .stroke(settings.accentTheme.color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\(Int((disk.usedFraction * 100).rounded()))%")
                    .font(.title2.bold())
                    .monospacedDigit()
                Text(settings.t("dashboard.used"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 108, height: 108)
        .animation(.easeInOut(duration: 0.4), value: disk.usedFraction)
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

            Button {
                if let url = ReportExporter.renderTempPDF(disk: disk, totalFreed: stats.totalBytesFreed, language: settings.language) {
                    reportPreviewURL = url
                    showReportPreview = true
                }
            } label: {
                Label(settings.t("dashboard.export_button"), systemImage: "square.and.arrow.up")
            }
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
