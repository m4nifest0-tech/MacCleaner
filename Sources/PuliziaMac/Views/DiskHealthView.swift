import SwiftUI

struct DiskHealthView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var health: DiskHealthInfo?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                explanation

                if let health {
                    statusCard(health)
                    metricsCard(health)
                    if !health.hasExtraSmartData {
                        Text(settings.t("diskhealth.extra_data_hint"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if isLoading {
                    ProgressView(settings.t("diskhealth.checking"))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    ContentUnavailableView(settings.t("diskhealth.unavailable"), systemImage: "externaldrive.badge.exclamationmark")
                }
            }
            .padding()
        }
        .navigationTitle(settings.t(AppSection.diskHealth.titleKey))
        .task {
            if health == nil { await load() }
        }
    }

    private var header: some View {
        HStack {
            Button {
                Task { await load() }
            } label: {
                Label(settings.t("diskhealth.refresh"), systemImage: "arrow.clockwise")
            }
            .disabled(isLoading)

            if isLoading {
                ProgressView().controlSize(.small)
            }
            Spacer()
        }
    }

    private var explanation: some View {
        Text(settings.t("diskhealth.explanation"))
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private func statusCard(_ health: DiskHealthInfo) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color(for: health.healthLevel))
                .frame(width: 20, height: 20)
                .shadow(color: color(for: health.healthLevel).opacity(0.5), radius: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(statusLabel(for: health.healthLevel))
                    .font(.title3.bold())
                Text(smartStatusLabel(health.smartStatus))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    private func metricsCard(_ health: DiskHealthInfo) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 14) {
            metricRow(icon: "cpu", title: settings.t("diskhealth.model"), value: health.modelName)
            metricRow(icon: "internaldrive", title: settings.t("diskhealth.available_space"), value: "\(health.availableBytes.formattedFileSize) / \(health.totalBytes.formattedFileSize)")
            metricRow(icon: "thermometer.medium", title: settings.t("diskhealth.temperature"), value: health.temperatureCelsius.map { "\($0)°C" } ?? settings.t("diskhealth.not_available_metric"))
            metricRow(icon: "gauge.with.dots.needle.67percent", title: settings.t("diskhealth.wear"), value: health.percentageUsed.map { "\($0)%" } ?? settings.t("diskhealth.not_available_metric"))
            metricRow(icon: "square.stack.3d.up", title: settings.t("diskhealth.tbw"), value: health.dataUnitsWrittenBytes.map { $0.formattedFileSize } ?? settings.t("diskhealth.not_available_metric"))
            metricRow(icon: "clock", title: settings.t("diskhealth.power_on_hours"), value: health.powerOnHours.map { "\($0) h" } ?? settings.t("diskhealth.not_available_metric"))
            metricRow(icon: "bolt", title: settings.t("diskhealth.trim"), value: trimLabel(health.trimSupported))
        }
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    private func metricRow(icon: String, title: String, value: String) -> some View {
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

    private func color(for level: DiskHealthLevel) -> Color {
        switch level {
        case .good: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }

    private func statusLabel(for level: DiskHealthLevel) -> String {
        switch level {
        case .good: return settings.t("diskhealth.status_good")
        case .warning: return settings.t("diskhealth.status_warning")
        case .critical: return settings.t("diskhealth.status_critical")
        }
    }

    private func smartStatusLabel(_ status: SMARTStatus) -> String {
        switch status {
        case .verified: return settings.t("diskhealth.smart_verified")
        case .failing: return settings.t("diskhealth.smart_failing")
        case .notSupported: return settings.t("diskhealth.smart_not_supported")
        case .unknown: return settings.t("diskhealth.smart_unknown")
        }
    }

    private func trimLabel(_ supported: Bool?) -> String {
        guard let supported else { return settings.t("diskhealth.not_available_metric") }
        return supported ? settings.t("diskhealth.trim_enabled") : settings.t("diskhealth.trim_disabled")
    }

    private func load() async {
        isLoading = true
        health = await DiskHealthProvider.current()
        isLoading = false
    }
}
