import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @Binding var selection: AppSection?

    @State private var disk: DiskOverview?
    @State private var system: SystemInfo?
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
                systemInfoCard
                quickAccessGrid
            }
            .padding()
        }
        .navigationTitle(settings.t(AppSection.dashboard.titleKey))
        .onAppear {
            disk = DiskOverview.current()
            system = SystemInfoProvider.current()
        }
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

    @ViewBuilder
    private var systemInfoCard: some View {
        if let system {
            VStack(alignment: .leading, spacing: 14) {
                Text(settings.t("dashboard.system_info"))
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 14) {
                    systemInfoRow(icon: "cpu", title: settings.t("dashboard.processor"), value: processorSummary(system))
                    systemInfoRow(icon: "memorychip", title: settings.t("dashboard.memory"), value: system.memoryBytes.formattedMemorySize)

                    if let disk {
                        systemInfoRow(icon: "internaldrive", title: settings.t("dashboard.storage"), value: disk.totalBytes.formattedFileSize)
                    }
                    if let batteryPercentage = system.batteryPercentage {
                        systemInfoRow(icon: batteryIcon(percentage: batteryPercentage, isCharging: system.isCharging), title: settings.t("dashboard.battery"), value: batterySummary(percentage: batteryPercentage, isCharging: system.isCharging))
                    }

                    systemInfoRow(icon: "wifi", title: settings.t("dashboard.network"), value: system.networkDescription ?? settings.t("dashboard.network_unavailable"))
                    systemInfoRow(icon: "desktopcomputer", title: system.computerName, value: "\(system.modelIdentifier) · macOS \(system.macOSVersion)")
                }
            }
            .padding()
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func systemInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(settings.accentTheme.color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private func processorSummary(_ system: SystemInfo) -> String {
        guard system.performanceCores > 0, system.efficiencyCores > 0 else {
            return "\(system.processorName) · \(system.totalCores) core"
        }
        let performanceLabel = settings.t("dashboard.cores_performance")
        let efficiencyLabel = settings.t("dashboard.cores_efficiency")
        return "\(system.processorName) · \(system.performanceCores) \(performanceLabel) + \(system.efficiencyCores) \(efficiencyLabel)"
    }

    private func batterySummary(percentage: Int, isCharging: Bool) -> String {
        isCharging ? "\(percentage)% · \(settings.t("dashboard.battery_charging"))" : "\(percentage)%"
    }

    private func batteryIcon(percentage: Int, isCharging: Bool) -> String {
        if isCharging { return "battery.100.bolt" }
        switch percentage {
        case ..<25: return "battery.25"
        case ..<50: return "battery.50"
        case ..<75: return "battery.75"
        default: return "battery.100"
        }
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
