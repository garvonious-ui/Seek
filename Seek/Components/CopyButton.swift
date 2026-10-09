import SwiftUI

/// Copies `text` to the clipboard, then briefly swaps to a "Copied" checkmark
/// so the tap has visible confirmation.
struct CopyButton: View {
    enum Style {
        /// Icon + "Copy" caption — matches the Favorite / Create Card actions on chat cards.
        case labeled
        /// Icon only — for tight rows like the Daily Verse card.
        case iconOnly
    }

    let text: String
    var style: Style = .labeled
    var tint: Color = Color(hex: "5B7B5E")

    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.15)) { copied = true }
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.easeInOut(duration: 0.15)) { copied = false }
            }
        } label: {
            switch style {
            case .labeled:
                Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(tint)
            case .iconOnly:
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(tint)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copied ? "Copied" : "Copy")
    }

    /// Shared clipboard format for a verse — same as LibraryView's "Copy" action.
    static func verseText(_ text: String, reference: String) -> String {
        "\(text)\n— \(reference)"
    }
}
