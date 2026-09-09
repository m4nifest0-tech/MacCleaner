import SwiftUI

struct SystemDataView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore

    @State private var result: SystemDataScanner.ScanResult?
    @State private var isScanning = false
    @State private var selectedSnapshots: Set<String> = []
    @State private var showDeleteConfirmation = false
    @State private var snapshotDeleteFailed = false
    @State private var isRebuildingSpotlight = false
    @State private var spotlightMessage: String?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                explanation

                if let result {
                    snapshotsCard(result)
                    cachesCard(result)
                    spotlightCard(result)
                } else if isScanning {
                    ProgressView(settings.t("systemdata.scanning"))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }
            }
            .padding()
        }
        .navigationTitle(settings.t(AppSection.systemData.titleKey))
        .task {
            if result == nil { await scan() }
        }
        .confirmationDialog(
            settings.t("systemdata.confirm_delete_snapshots"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(settings.t("common.delete"), role: .destructive) { deleteSelectedSnapshots() }
            Button(settings.t("common.cancel"), role: .cancel) {}
        }
    }

    private var header: some View {
        HStack {
            Button {
                Task { await scan() }
            } label: {
                Label(settings.t("systemdata.scan_button"), systemImage: "arrow.clockwise")
            }
            .disabled(isScanning)

            if isScanning {
                ProgressView().controlSize(.small)
            }
            Spacer()
        }
    }

    private var explanation: some View {
        Text(settings.t("systemdata.explanation"))
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    // MARK: - Snapshot APFS

    @ViewBuilder
    private func snapshotsCard(_ result: SystemDataScanner.ScanResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(settings.t("systemdata.snapshots_header"))
                    .font(.headline)
                Spacer()
                if !selectedSnapshots.isEmpty {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(settings.t("systemdata.delete_snapshots"), systemImage: "trash")
                    }
                }
            }

            Text(settings.t("systemdata.snapshots_explanation"))
                .font(.caption)
                .foregroundStyle(.secondary)

            if snapshotDeleteFailed {
                Text(settings.t("systemdata.delete_snapshots_failed"))
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            if result.snapshots.isEmpty {
                Text(settings.t("systemdata.snapshots_empty"))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 4) {
                    ForEach(result.snapshots) { snapshot in
                        snapshotRow(snapshot)
                    }
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    private func snapshotRow(_ snapshot: APFSSnapshot) -> some View {
        HStack {
            Button {
                toggle(snapshot)
            } label: {
                Image(systemName: selectedSnapshots.contains(snapshot.id) ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.plain)

            Image(systemName: "camera.aperture")
                .foregroundStyle(.secondary)

            Text(snapshot.date.map(dateFormatter.string(from:)) ?? snapshot.fullName)
        }
        .contentShape(Rectangle())
        .onTapGesture { toggle(snapshot) }
    }

    private func toggle(_ snapshot: APFSSnapshot) {
        if selectedSnapshots.contains(snapshot.id) {
            selectedSnapshots.remove(snapshot.id)
        } else {
            selectedSnapshots.insert(snapshot.id)
        }
    }

    // MARK: - Cache di sistema

    @ViewBuilder
    private func cachesCard(_ result: SystemDataScanner.ScanResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(settings.t("systemdata.caches_header"))
                .font(.headline)

            cacheRow(title: settings.t("systemdata.quicklook_cache"), file: result.quickLookCache)
            Divider()
            cacheRow(title: settings.t("systemdata.coresimulator_cache"), file: result.coreSimulatorCache)
        }
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func cacheRow(title: String, file: SystemDataFile?) -> some View {
        HStack {
            Image(systemName: "internaldrive")
                .foregroundStyle(.secondary)
            Text(title)
            Spacer()
            if let file {
                SizeBadge(bytes: file.sizeBytes)
                Button(role: .destructive) {
                    moveToTrash(file)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            } else {
                Text(settings.t("systemdata.cache_not_present"))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func moveToTrash(_ file: SystemDataFile) {
        let failures = TrashService.moveToTrash([file.path])
        if failures.isEmpty {
            stats.recordFreed(file.sizeBytes)
        }
        Task { await scan() }
    }

    // MARK: - Indice Spotlight

    @ViewBuilder
    private func spotlightCard(_ result: SystemDataScanner.ScanResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(settings.t("systemdata.spotlight_header"))
                .font(.headline)

            Text(settings.t("systemdata.spotlight_explanation"))
                .font(.caption)
                .foregroundStyle(.secondary)

            if result.spotlightPermissionDenied {
                PermissionBanner(missingCount: 1)
            }

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                if let size = result.spotlightIndexSize {
                    SizeBadge(bytes: size)
                } else if !result.spotlightPermissionDenied {
                    Text(settings.t("systemdata.spotlight_unavailable"))
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if isRebuildingSpotlight {
                    ProgressView().controlSize(.small)
                }
                Button {
                    rebuildSpotlightIndex()
                } label: {
                    Label(settings.t("systemdata.spotlight_rebuild"), systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(isRebuildingSpotlight)
            }

            if let spotlightMessage {
                Text(spotlightMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    private func rebuildSpotlightIndex() {
        isRebuildingSpotlight = true
        spotlightMessage = nil
        Task {
            let result = SystemDataScanner.rebuildSpotlightIndex()
            spotlightMessage = result.success ? settings.t("systemdata.spotlight_rebuild_started") : result.errorMessage
            isRebuildingSpotlight = false
        }
    }

    // MARK: - Scansione

    private func scan() async {
        isScanning = true
        selectedSnapshots.removeAll()
        snapshotDeleteFailed = false
        result = await SystemDataScanner.scan()
        isScanning = false
    }

    private func deleteSelectedSnapshots() {
        guard let result else { return }
        let toDelete = result.snapshots.filter { selectedSnapshots.contains($0.id) }
        Task {
            var anyFailed = false
            for snapshot in toDelete {
                let success = await SystemDataScanner.deleteSnapshot(snapshot)
                if !success { anyFailed = true }
            }
            snapshotDeleteFailed = anyFailed
            await scan()
        }
    }
}
