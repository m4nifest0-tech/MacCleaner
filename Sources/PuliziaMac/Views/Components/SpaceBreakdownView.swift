import SwiftUI

/// Vista "Grafica" di Esplora Disco: anello proporzionale (`DonutChartView`) più una
/// legenda interattiva accanto — selezione e navigazione restano sulla legenda, dove i
/// bersagli sono grandi abbastanza da poterli usare comodamente, invece che su archi
/// sottili difficili da colpire con precisione.
struct SpaceBreakdownView: View {
    @EnvironmentObject private var settings: AppSettings

    let entries: [DiskExplorerEntry]
    let isSelected: (DiskExplorerEntry) -> Bool
    let isExcluded: (DiskExplorerEntry) -> Bool
    let onToggleSelection: (DiskExplorerEntry) -> Void
    let onNavigate: (DiskExplorerEntry) -> Void

    private static let maxSlices = 12
    private static let palette: [Color] = [.blue, .teal, .purple, .orange, .green, .pink, .indigo, .mint, .cyan, .red]

    private var topEntries: [DiskExplorerEntry] { Array(entries.prefix(Self.maxSlices)) }
    private var totalBytes: Int64 { entries.reduce(0) { $0 + $1.sizeBytes } }
    private var selectedIDs: Set<URL> { Set(topEntries.filter(isSelected).map(\.id)) }

    var body: some View {
        HStack(alignment: .center, spacing: 32) {
            DonutChartView(
                entries: topEntries,
                colors: Self.palette,
                selectedIDs: selectedIDs,
                totalLabel: settings.t("diskexplorer.total_label"),
                totalValue: totalBytes.formattedFileSize
            )
            .frame(width: 240, height: 240)

            legend
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var legend: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(topEntries.enumerated()), id: \.element.id) { index, entry in
                    legendRow(entry, color: Self.palette[index % Self.palette.count])
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendRow(_ entry: DiskExplorerEntry, color: Color) -> some View {
        let excluded = isExcluded(entry)
        let selected = isSelected(entry)

        return HStack(spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10)

            Button {
                onToggleSelection(entry)
            } label: {
                Image(systemName: selected ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.plain)
            .disabled(excluded)
            .opacity(excluded ? 0.3 : 1)

            Text(entry.name)
                .lineLimit(1)

            if excluded {
                Image(systemName: "lock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if entry.isNavigable {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            SizeBadge(bytes: entry.sizeBytes)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(selected ? color.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture {
            guard entry.isNavigable || !excluded else { return }
            if entry.isNavigable {
                onNavigate(entry)
            } else {
                onToggleSelection(entry)
            }
        }
    }
}
