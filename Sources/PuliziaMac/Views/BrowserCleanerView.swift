import SwiftUI

struct BrowserCleanerView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore

    @State private var scanResult: BrowserCacheScanner.ScanResult?
    @State private var isScanning = false
    @State private var selection: Set<URL> = []
    @State private var showCleanConfirmation = false
    @State private var lastFailures: [TrashService.Failure] = []

    private var items: [BrowserCacheItem] { scanResult?.items ?? [] }

    private var selectedSize: Int64 {
        items.filter { selection.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
    }

    private var confirmTrashTitle: String {
        settings.language == .italian
            ? "Spostare \(selection.count) cache (\(selectedSize.formattedFileSize)) nel Cestino?"
            : "Move \(selection.count) caches (\(selectedSize.formattedFileSize)) to the Trash?"
    }

    private var failuresText: String {
        settings.language == .italian
            ? "Non è stato possibile spostare \(lastFailures.count) elementi nel Cestino."
            : "Couldn't move \(lastFailures.count) items to the Trash."
    }

    private var selectionSummary: String {
        settings.language == .italian
            ? "\(selection.count) selezionati · \(selectedSize.formattedFileSize)"
            : "\(selection.count) selected · \(selectedSize.formattedFileSize)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            explanation

            if (scanResult?.permissionIssues ?? 0) > 0 {
                PermissionBanner(missingCount: scanResult?.permissionIssues ?? 0)
            }
            if !lastFailures.isEmpty {
                Text(failuresText)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(settings.t(AppSection.browserCleaner.titleKey))
        .task {
            if scanResult == nil { await runScan() }
        }
        .confirmationDialog(
            confirmTrashTitle,
            isPresented: $showCleanConfirmation,
            titleVisibility: .visible
        ) {
            Button(settings.t("common.move_to_trash"), role: .destructive) { cleanSelected() }
            Button(settings.t("common.cancel"), role: .cancel) {}
        }
    }

    private var header: some View {
        HStack {
            Button {
                Task { await runScan() }
            } label: {
                Label(settings.t("cache.scan"), systemImage: "arrow.clockwise")
            }
            .disabled(isScanning)

            if isScanning {
                ProgressView().controlSize(.small)
            }

            Spacer()

            if !selection.isEmpty {
                Text(selectionSummary)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                showCleanConfirmation = true
            } label: {
                Label(settings.t("cache.clean_selected"), systemImage: "trash")
            }
            .disabled(selection.isEmpty)
        }
    }

    private var explanation: some View {
        Text(settings.t("browser.explanation"))
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var content: some View {
        if isScanning && scanResult == nil {
            VStack {
                Spacer()
                ProgressView(settings.t("cache.scanning"))
                Spacer()
            }
        } else if items.isEmpty {
            ContentUnavailableView(settings.t("browser.empty"), systemImage: "globe")
        } else {
            List(items) { item in
                itemRow(item)
            }
        }
    }

    private func itemRow(_ item: BrowserCacheItem) -> some View {
        HStack {
            Button {
                toggle(item)
            } label: {
                Image(systemName: selection.contains(item.id) ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.plain)

            Image(systemName: "globe")
                .foregroundStyle(.secondary)

            Text(item.browserName)

            Spacer()
            SizeBadge(bytes: item.sizeBytes)
        }
        .contentShape(Rectangle())
        .onTapGesture { toggle(item) }
    }

    private func toggle(_ item: BrowserCacheItem) {
        if selection.contains(item.id) {
            selection.remove(item.id)
        } else {
            selection.insert(item.id)
        }
    }

    private func runScan() async {
        isScanning = true
        selection.removeAll()
        lastFailures = []
        scanResult = await BrowserCacheScanner.scan()
        isScanning = false
    }

    private func cleanSelected() {
        let selectedItems = items.filter { selection.contains($0.id) }
        Task {
            lastFailures = TrashService.moveToTrash(selectedItems.map(\.path))
            let failedPaths = Set(lastFailures.map(\.path))
            let freed = selectedItems.filter { !failedPaths.contains($0.path) }.reduce(0) { $0 + $1.sizeBytes }
            stats.recordFreed(freed)
            await runScan()
        }
    }
}
