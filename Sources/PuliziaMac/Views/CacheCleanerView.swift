import SwiftUI

struct CacheCleanerView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var scanResult: CacheScanner.ScanResult?
    @State private var isScanning = false
    @State private var selection: Set<URL> = []
    @State private var scanTask: Task<Void, Never>?
    @State private var isCleaning = false
    @State private var showCleanConfirmation = false
    @State private var lastFailures: [TrashService.Failure] = []

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

    private var confirmTrashTitle: String {
        settings.language == .italian
            ? "Spostare \(selection.count) elementi (\(selectedSize.formattedFileSize)) nel Cestino?"
            : "Move \(selection.count) items (\(selectedSize.formattedFileSize)) to the Trash?"
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

            if let scanResult, !scanResult.permissionIssues.isEmpty {
                PermissionBanner(missingCount: scanResult.permissionIssues.count)
            }

            if !lastFailures.isEmpty {
                Text(failuresText)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            content
        }
        .padding()
        .navigationTitle(settings.t(AppSection.cacheCleaner.titleKey))
        .task {
            if scanResult == nil { await runScan() }
        }
        .confirmationDialog(
            confirmTrashTitle,
            isPresented: $showCleanConfirmation,
            titleVisibility: .visible
        ) {
            Button(settings.t("common.move_to_trash"), role: .destructive) {
                cleanSelected()
            }
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

            if !selection.isEmpty {
                Text(selectionSummary)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                showCleanConfirmation = true
            } label: {
                Label(settings.t("cache.clean_selected"), systemImage: "trash")
            }
            .disabled(selection.isEmpty || isCleaning)
        }
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
            ContentUnavailableView(settings.t("cache.empty"), systemImage: "checkmark.circle")
        } else {
            List {
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
        selection.removeAll()
        lastFailures = []
        let result = await CacheScanner.scan()
        scanResult = result
        isScanning = false
    }

    private func cleanSelected() {
        guard let scanResult else { return }
        let pathsToClean = scanResult.items.filter { selection.contains($0.id) }.map(\.path)
        isCleaning = true
        Task {
            let failures = TrashService.moveToTrash(pathsToClean)
            lastFailures = failures
            isCleaning = false
            await runScan()
        }
    }
}
