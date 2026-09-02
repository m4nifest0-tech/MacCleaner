import SwiftUI

/// Anello multi-segmento, stile coerente con l'indicatore circolare della Panoramica:
/// ogni voce diventa un arco con lunghezza proporzionale alla dimensione, estremità
/// arrotondate, un piccolo distacco tra un segmento e l'altro. Puramente visivo — la
/// selezione/navigazione avviene dalla legenda accanto, non toccando l'anello.
struct DonutChartView: View {
    let entries: [DiskExplorerEntry]
    let colors: [Color]
    let selectedIDs: Set<URL>
    let totalLabel: String
    let totalValue: String

    private static let gap: Double = 0.006

    private var total: Double {
        entries.reduce(0.0) { $0 + Double(max($1.sizeBytes, 0)) }
    }

    private func fraction(_ entry: DiskExplorerEntry) -> Double {
        guard total > 0 else { return 0 }
        return Double(entry.sizeBytes) / total
    }

    private func start(before index: Int) -> Double {
        entries.prefix(index).reduce(0.0) { $0 + fraction($1) }
    }

    var body: some View {
        ZStack {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                let s = start(before: index)
                let e = max(s + fraction(entry) - Self.gap, s)
                Circle()
                    .trim(from: s, to: e)
                    .stroke(
                        colors[index % colors.count],
                        style: StrokeStyle(lineWidth: selectedIDs.contains(entry.id) ? 32 : 26, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: selectedIDs.contains(entry.id))
            }

            VStack(spacing: 2) {
                Text(totalValue)
                    .font(.title2.bold())
                    .monospacedDigit()
                Text(totalLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
