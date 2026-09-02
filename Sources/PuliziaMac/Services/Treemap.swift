import Foundation
import CoreGraphics

struct TreemapRect: Identifiable {
    let entry: DiskExplorerEntry
    let rect: CGRect
    var id: URL { entry.id }
}

/// Algoritmo di "squarified treemap" (Bruls, Huizing, van Wijk): dispone un elenco di
/// voci in rettangoli con area proporzionale alla loro dimensione, preferendo forme
/// vicine al quadrato invece di schegge sottilissime — lo stesso principio usato da
/// strumenti come DaisyDisk o WinDirStat per rendere visivamente lo spazio occupato.
enum Treemap {
    static func layout(entries: [DiskExplorerEntry], in rect: CGRect) -> [TreemapRect] {
        let items = entries.map { (entry: $0, value: max(Double($0.sizeBytes), 1)) }
        let total = items.reduce(0.0) { $0 + $1.value }
        guard total > 0, rect.width > 1, rect.height > 1 else { return [] }
        let areaPerValue = Double(rect.width) * Double(rect.height) / total
        return squarify(items: items, rect: rect, areaPerValue: areaPerValue)
    }

    private static func squarify(
        items: [(entry: DiskExplorerEntry, value: Double)],
        rect: CGRect,
        areaPerValue: Double
    ) -> [TreemapRect] {
        guard !items.isEmpty, rect.width > 0.5, rect.height > 0.5 else { return [] }

        var remaining = items
        var row: [(entry: DiskExplorerEntry, value: Double)] = []
        let shortSide = Double(min(rect.width, rect.height))

        func worst(_ candidateRow: [(entry: DiskExplorerEntry, value: Double)]) -> Double {
            let areas = candidateRow.map { $0.value * areaPerValue }
            guard let maxA = areas.max(), let minA = areas.min(), minA > 0 else { return .infinity }
            let sum = areas.reduce(0, +)
            let s2 = shortSide * shortSide
            return max((s2 * maxA) / (sum * sum), (sum * sum) / (s2 * minA))
        }

        while let next = remaining.first {
            let candidate = row + [next]
            if row.isEmpty || worst(candidate) <= worst(row) {
                row = candidate
                remaining.removeFirst()
            } else {
                break
            }
        }

        let rowArea = row.reduce(0.0) { $0 + $1.value * areaPerValue }
        var results: [TreemapRect] = []
        let nextRect: CGRect

        if rect.width >= rect.height {
            let colWidth = rect.height > 0 ? rowArea / Double(rect.height) : 0
            var y = Double(rect.minY)
            for (entry, value) in row {
                let h = rowArea > 0 ? (value * areaPerValue / rowArea) * Double(rect.height) : 0
                results.append(TreemapRect(entry: entry, rect: CGRect(x: rect.minX, y: y, width: colWidth, height: h)))
                y += h
            }
            nextRect = CGRect(x: rect.minX + colWidth, y: rect.minY, width: rect.width - colWidth, height: rect.height)
        } else {
            let rowHeight = rect.width > 0 ? rowArea / Double(rect.width) : 0
            var x = Double(rect.minX)
            for (entry, value) in row {
                let w = rowArea > 0 ? (value * areaPerValue / rowArea) * Double(rect.width) : 0
                results.append(TreemapRect(entry: entry, rect: CGRect(x: x, y: rect.minY, width: w, height: rowHeight)))
                x += w
            }
            nextRect = CGRect(x: rect.minX, y: rect.minY + rowHeight, width: rect.width, height: rect.height - rowHeight)
        }

        results.append(contentsOf: squarify(items: remaining, rect: nextRect, areaPerValue: areaPerValue))
        return results
    }
}
