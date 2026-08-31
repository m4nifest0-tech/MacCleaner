import SwiftUI

/// Pulizia con un click: esegue la stessa scansione sicura di "Cache e File
/// Temporanei" (più il flush della cache DNS), ma seleziona già tutto tranne il
/// Cestino, così l'utente deve solo controllare l'elenco e confermare — niente
/// selezione manuale categoria per categoria. Resta comunque richiesta UNA conferma
/// esplicita prima di spostare qualunque cosa nel Cestino: coerente con il principio
/// "nessuna cancellazione senza consenso" già seguito nel resto dell'app.
struct SmartCleanView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @EnvironmentObject private var exclusions: ExclusionStore

    @State private var scanResult: CacheScanner.ScanResult?
    @State private var isScanning = false
    @State private var selection: Set<URL> = []
    @State private var flushDNS = true
    @State private var isCleaning = false
    @State private var showCleanConfirmation = false
    @State private var lastFailures: [TrashService.Failure] = []
    @State private var dnsResultMessage: String?

    private var groupedItems: [(CleanableCategory, [CleanableItem])] {
        guard let scanResult else { return [] }
        let grouped = Dictionary(grouping: scanResult.items, by: \.category)
        return CleanableCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    private var selectedSize: Int64 {
        guard let scanResult else { return 0 }
        return scanResult.items.filter { selection.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
    }

    private var hasSomethingToClean: Bool {
        !selection.isEmpty || flushDNS
    }

    private var confirmTitle: String {
        let filesPart = settings.language == .italian
            ? "\(selection.count) elementi (\(selectedSize.formattedFileSize))"
            : "\(selection.count) items (\(selectedSize.formattedFileSize))"
        if flushDNS {
            return settings.language == .italian
                ? "Pulire \(filesPart) e svuotare la cache DNS?"
                : "Clean \(filesPart) and flush the DNS cache?"
        }
        return settings.language == .italian ? "Pulire \(filesPart)?" : "Clean \(filesPart)?"
    }

    private var failuresText: String {
        settings.language == .italian
            ? "Non è stato possibile spostare \(lastFailures.count) elementi nel Cestino."
            : "Couldn't move \(lastFailures.count) items to the Trash."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            explanation

            if let scanResult, !scanResult.permissionIssues.isEmpty {
                PermissionBanner(missingCount: scanResult.permissionIssues.count)
            }
            if !lastFailures.isEmpty {
                Text(failuresText)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
            if let dnsResultMessage {
                Text(dnsResultMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(settings.t(AppSection.smartClean.titleKey))
        .task {
            if scanResult == nil { await runScan() }
        }
        .confirmationDialog(
            confirmTitle,
            isPresented: $showCleanConfirmation,
            titleVisibility: .visible
        ) {
            Button(settings.t("smartclean.clean_button"), role: .destructive) { cleanNow() }
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
            .disabled(isScanning || isCleaning)

            if isScanning {
                ProgressView().controlSize(.small)
            }

            Spacer()

            Button(role: .destructive) {
                showCleanConfirmation = true
            } label: {
                Label(settings.t("smartclean.clean_button"), systemImage: "wand.and.sparkles")
            }
            .disabled(!hasSomethingToClean || isCleaning || isScanning)
        }
    }

    private var explanation: some View {
        Text(settings.t("smartclean.explanation"))
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let scanResult, scanResult.items.isEmpty {
            dnsOnlyList
        } else {
            List {
                dnsRow
                ForEach(groupedItems, id: \.0) { category, items in
                    Section {
                        ForEach(items) { item in
                            itemRow(item)
                        }
                    } header: {
                        HStack {
                            Text(settings.t(category.titleKey))
                            Spacer()
                            SizeBadge(bytes: items.reduce(0) { $0 + $1.sizeBytes })
                        }
                    }
                }
            }
        }
    }

    /// Quando non c'è nulla da ripulire nei file, mostriamo comunque la riga DNS: il
    /// flush resta un'azione utile a sé stante.
    private var dnsOnlyList: some View {
        List {
            dnsRow
        }
    }

    private var dnsRow: some View {
        HStack {
            Button {
                flushDNS.toggle()
            } label: {
                Image(systemName: flushDNS ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading) {
                Text(settings.t("smartclean.dns_row_title"))
                Text(settings.t("smartclean.dns_row_subtitle"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { flushDNS.toggle() }
    }

    private func itemRow(_ item: CleanableItem) -> some View {
        HStack {
            Button {
                toggle(item)
            } label: {
                Image(systemName: selection.contains(item.id) ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading) {
                Text(item.name)
                Text(item.path.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
            SizeBadge(bytes: item.sizeBytes)
        }
        .contentShape(Rectangle())
        .onTapGesture { toggle(item) }
    }

    private func toggle(_ item: CleanableItem) {
        if selection.contains(item.id) {
            selection.remove(item.id)
        } else {
            selection.insert(item.id)
        }
    }

    private func runScan() async {
        isScanning = true
        lastFailures = []
        dnsResultMessage = nil
        let result = await CacheScanner.scan(excludedFolders: exclusions.excludedFolders)
        scanResult = result
        // Seleziona automaticamente tutto tranne il Cestino: svuotarlo è un'azione
        // definitiva (non uno spostamento reversibile), quindi resta opt-in manuale.
        selection = Set(result.items.filter { $0.category != .trash }.map(\.id))
        isScanning = false
    }

    private func cleanNow() {
        guard let scanResult else { return }
        let itemsToClean = scanResult.items.filter { selection.contains($0.id) }
        isCleaning = true
        Task {
            if !itemsToClean.isEmpty {
                let failures = TrashService.moveToTrash(itemsToClean.map(\.path))
                lastFailures = failures
                let failedPaths = Set(failures.map(\.path))
                let freed = itemsToClean.filter { !failedPaths.contains($0.path) }.reduce(0) { $0 + $1.sizeBytes }
                stats.recordFreed(freed)
            }

            if flushDNS {
                let result = await NetworkCacheService.flushDNSCache()
                dnsResultMessage = result.success ? settings.t("smartclean.dns_success") : result.errorMessage
            }

            isCleaning = false
            await runScan()
        }
    }
}
