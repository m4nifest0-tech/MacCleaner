import SwiftUI
import AppKit

private enum ArchFilter: CaseIterable, Identifiable {
    case intelOnly
    case universal
    case all

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .intelOnly: return "arch.filter_intel"
        case .universal: return "arch.filter_universal"
        case .all: return "arch.filter_all"
        }
    }
}

struct ArchScannerView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @State private var apps: [AppBundleInfo] = []
    @State private var isScanning = false
    @State private var filter: ArchFilter = .intelOnly

    @State private var estimatingAppID: URL?
    @State private var thinningTarget: AppBundleInfo?
    @State private var estimatedSavings: Int64 = 0
    @State private var showThinConfirmation = false
    @State private var thinningAppID: URL?
    @State private var lastThinResult: ThinResult?

    private var visibleApps: [AppBundleInfo] {
        switch filter {
        case .intelOnly: return apps.filter(\.isIntelOnly)
        case .universal: return apps.filter(\.isUniversal)
        case .all: return apps
        }
    }

    private var intelOnlyApps: [AppBundleInfo] {
        apps.filter(\.isIntelOnly)
    }

    private var totalIntelOnlySize: Int64 {
        intelOnlyApps.reduce(0) { $0 + $1.sizeBytes }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            explanation
            resultBanner
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(settings.t(AppSection.archScanner.titleKey))
        .task {
            if apps.isEmpty { await runScan() }
        }
        .confirmationDialog(
            thinConfirmationTitle,
            isPresented: $showThinConfirmation,
            titleVisibility: .visible
        ) {
            Button(settings.t("arch.remove_intel_button"), role: .destructive) {
                if let thinningTarget { thin(thinningTarget) }
            }
            Button(settings.t("common.cancel"), role: .cancel) { thinningTarget = nil }
        } message: {
            Text(thinConfirmationMessage)
        }
    }

    private var thinConfirmationTitle: String {
        let name = thinningTarget?.name ?? ""
        return settings.language == .italian
            ? "Rimuovere la parte Intel da \"\(name)\"?"
            : "Remove the Intel part from \"\(name)\"?"
    }

    private var thinConfirmationMessage: String {
        let size = estimatedSavings.formattedFileSize
        return settings.language == .italian
            ? "Circa \(size) recuperabili. L'app verrà ri-firmata; alcune app (soprattutto con protezioni anti-manomissione) potrebbero smettere di funzionare e richiedere la reinstallazione. Non viene creato un backup automatico. Se l'app è stata installata con un installer .pkg, macOS chiederà la password di amministratore."
            : "About \(size) reclaimable. The app will be re-signed; some apps (especially ones with tamper-detection) may stop working and need reinstalling. No automatic backup is created. If the app was installed via a .pkg installer, macOS will ask for the administrator password."
    }

    private var header: some View {
        HStack {
            Button {
                Task { await runScan() }
            } label: {
                Label(settings.t("arch.scan_button"), systemImage: "arrow.clockwise")
            }
            .disabled(isScanning)

            if isScanning {
                ProgressView().controlSize(.small)
            }

            Picker("", selection: $filter) {
                ForEach(ArchFilter.allCases) { option in
                    Text(settings.t(option.titleKey)).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 420)

            Spacer()

            if !intelOnlyApps.isEmpty {
                Text(intelOnlySummary)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var intelOnlySummary: String {
        let size = totalIntelOnlySize.formattedFileSize
        return settings.language == .italian
            ? "\(intelOnlyApps.count) app · \(size) occupati"
            : "\(intelOnlyApps.count) apps · \(size) used"
    }

    private var explanation: some View {
        Text(settings.t("arch.explanation"))
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var resultBanner: some View {
        if let lastThinResult {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: lastThinResult.success ? "checkmark.circle" : "exclamationmark.triangle")
                        .foregroundStyle(lastThinResult.success ? .green : .red)
                    Text(resultBannerText(lastThinResult))
                    Spacer()
                    Button {
                        self.lastThinResult = nil
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.borderless)
                }

                if lastThinResult.requiresAppManagementPermission {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(settings.t("arch.app_management_hint"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(settings.t("common.open_system_settings")) {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                    }
                }
            }
            .font(.callout)
            .padding(8)
            .background((lastThinResult.success ? Color.green : Color.red).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func resultBannerText(_ result: ThinResult) -> String {
        if result.success {
            return settings.language == .italian
                ? "\(result.appName): liberati \(result.freedBytes.formattedFileSize)."
                : "\(result.appName): freed \(result.freedBytes.formattedFileSize)."
        }
        let fallback = settings.language == .italian ? "operazione non riuscita" : "operation failed"
        return "\(result.appName): \(result.errorMessage ?? fallback)."
    }

    @ViewBuilder
    private var content: some View {
        if isScanning && apps.isEmpty {
            VStack {
                Spacer()
                ProgressView(settings.t("arch.analyzing"))
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if visibleApps.isEmpty {
            ContentUnavailableView(
                settings.t(emptyStateKey),
                systemImage: "checkmark.circle"
            )
        } else {
            List(visibleApps) { app in
                appRow(app)
            }
        }
    }

    private var emptyStateKey: String {
        switch filter {
        case .intelOnly: return "arch.empty_intel"
        case .universal: return "arch.empty_universal"
        case .all: return "arch.empty_all"
        }
    }

    private func appRow(_ app: AppBundleInfo) -> some View {
        HStack {
            AppIconView(path: app.bundleURL)

            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Text(app.name)
                    if app.isIntelOnly {
                        badge(settings.t("arch.badge_intel"), color: .orange)
                    } else if app.isUniversal {
                        badge(settings.t("arch.badge_universal"), color: .blue)
                    }
                }
                Text([app.version, app.architectures.joined(separator: ", ")].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            SizeBadge(bytes: app.sizeBytes)

            if app.isUniversal {
                thinButton(for: app)
            }

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([app.bundleURL])
            } label: {
                Image(systemName: "finder")
            }
            .buttonStyle(.borderless)
            .help(settings.t("common.reveal_finder"))
        }
    }

    @ViewBuilder
    private func thinButton(for app: AppBundleInfo) -> some View {
        if app.isMacAppStoreApp {
            Text(settings.t("arch.mas_unavailable"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .help(settings.t("arch.mas_unavailable_help"))
        } else if thinningAppID == app.id {
            ProgressView().controlSize(.small)
        } else if estimatingAppID == app.id {
            ProgressView().controlSize(.small)
        } else {
            Button(settings.t("arch.remove_intel_button")) {
                startThinFlow(for: app)
            }
            .font(.caption)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
    }

    private func startThinFlow(for app: AppBundleInfo) {
        estimatingAppID = app.id
        Task {
            estimatedSavings = await UniversalAppThinner.estimateIntelSavings(for: app.bundleURL)
            estimatingAppID = nil
            thinningTarget = app
            showThinConfirmation = true
        }
    }

    private func thin(_ app: AppBundleInfo) {
        thinningAppID = app.id
        Task {
            let result = await UniversalAppThinner.removeIntelSlice(from: app)
            lastThinResult = result
            if result.success { stats.recordFreed(result.freedBytes) }
            thinningAppID = nil
            thinningTarget = nil
            await runScan()
        }
    }

    private func runScan() async {
        isScanning = true
        apps = await ArchScanner.scan()
        isScanning = false
    }
}
