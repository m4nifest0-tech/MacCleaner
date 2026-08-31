import SwiftUI

struct SizeBadge: View {
    let bytes: Int64

    var body: some View {
        Text(bytes.formattedFileSize)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.secondary)
    }
}
