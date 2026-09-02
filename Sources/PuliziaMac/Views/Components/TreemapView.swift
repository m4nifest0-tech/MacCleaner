import SwiftUI

/// Mappa visiva delle voci di una cartella: ogni rettangolo ha un'area proporzionale
/// alla dimensione reale, per rendere a colpo d'occhio dove va lo spazio (come
/// DaisyDisk/WinDirStat), in alternativa alla lista testuale.
struct TreemapView: View {
    let entries: [DiskExplorerEntry]
    let isSelected: (DiskExplorerEntry) -> Bool
    let isExcluded: (DiskExplorerEntry) -> Bool
    let onTap: (DiskExplorerEntry) -> Void

    /// Oltre questo numero di voci le schegge diventano illeggibili: mostriamo solo le
    /// più grandi, che sono comunque quelle che contano per capire dove va lo spazio.
    private static let maxTiles = 40

    private static let palette: [Color] = [
        .blue, .teal, .purple, .orange, .green, .pink, .indigo, .mint, .cyan, .yellow
    ]

    var body: some View {
        let visibleEntries = Array(entries.prefix(Self.maxTiles))
        GeometryReader { geo in
            let rects = Treemap.layout(entries: visibleEntries, in: CGRect(origin: .zero, size: geo.size))
            ZStack(alignment: .topLeading) {
                ForEach(Array(rects.enumerated()), id: \.element.id) { index, tile in
                    tileView(tile, colorIndex: index)
                        .frame(width: max(tile.rect.width - 2, 0), height: max(tile.rect.height - 2, 0))
                        .position(x: tile.rect.midX, y: tile.rect.midY)
                }
            }
        }
    }

    private func tileView(_ tile: TreemapRect, colorIndex: Int) -> some View {
        let excluded = isExcluded(tile.entry)
        let selected = isSelected(tile.entry)
        let color = Self.palette[colorIndex % Self.palette.count]

        return VStack(alignment: .leading, spacing: 2) {
            if tile.rect.width > 46 && tile.rect.height > 26 {
                Text(tile.entry.name)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(tile.entry.sizeBytes.formattedFileSize)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(excluded ? Color.gray : color.opacity(0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(selected ? Color.white : Color.black.opacity(0.15), lineWidth: selected ? 2 : 1)
        )
        .contentShape(Rectangle())
        .opacity(excluded ? 0.5 : 1)
        .onTapGesture { onTap(tile.entry) }
        .help(tile.entry.name + " · " + tile.entry.sizeBytes.formattedFileSize)
    }
}
