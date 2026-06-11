import SwiftUI

/// The actual card view that gets rendered to an image OR shown as a
/// thumbnail. All internal dimensions scale off `renderSize.width` so the
/// 1080x1920 export and a small library-grid thumbnail use the same layout
/// — no more "looks great in preview, tiny in library" mismatch.
struct VerseCardView: View {
    let verseText: String
    let verseReference: String
    let template: CardTemplate
    /// Optional AI interpretation line, printed below the reference when set.
    var interpretation: String? = nil
    /// Defaults to 9:16 IG story (1080x1920). Pass a smaller size for a
    /// thumbnail; everything scales proportionally.
    var renderSize: CGSize = CGSize(width: 1080, height: 1920)

    static let renderWidth: CGFloat = 1080
    static let renderHeight: CGFloat = 1920

    /// Scale factor relative to the canonical 1080-wide render. Use this to
    /// scale fonts, padding, spacing — anything that should track the
    /// container size.
    private var scale: CGFloat { renderSize.width / Self.renderWidth }

    var body: some View {
        ZStack {
            if let gradient = template.backgroundGradient {
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                template.backgroundColor
            }

            VStack(spacing: 40 * scale) {
                Spacer()

                Text(verseText)
                    .font(.custom(template.fontName, size: fontSize * scale))
                    .lineSpacing(20 * scale)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(template.textColor)
                    .padding(.horizontal, 100 * scale)

                Text("— \(verseReference)")
                    .font(.system(size: 44 * scale, weight: .semibold))
                    .foregroundStyle(template.referenceColor)

                if let interpretation, !interpretation.isEmpty {
                    Text(interpretation)
                        .font(.system(size: 46 * scale, weight: .semibold))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(template.textColor.opacity(0.88))
                        .padding(.horizontal, 110 * scale)
                        .padding(.top, 14 * scale)
                }

                Spacer()

                // Wordmark watermark — uses the same brand asset as launch
                // screen / Home header. .template rendering recolors it to
                // the template's text color so it reads on any background.
                Image("Wordmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100 * scale)
                    .foregroundStyle(template.textColor.opacity(0.45))
                    .padding(.bottom, 60 * scale)
            }
        }
        .frame(width: renderSize.width, height: renderSize.height)
    }

    /// Auto-size font based on verse length. Scaled by `scale` at use site.
    /// When an interpretation is also printed, shrink slightly to leave room
    /// for it so a long verse + interpretation doesn't overflow the card.
    private var fontSize: CGFloat {
        let length = verseText.count
        let base: CGFloat
        if length < 80 { base = 104 }
        else if length < 150 { base = 88 }
        else if length < 250 { base = 72 }
        else if length < 400 { base = 58 }
        else { base = 48 }

        let hasInterpretation = !(interpretation ?? "").isEmpty
        return hasInterpretation ? max(42, base - 8) : base
    }
}

// MARK: - Preview thumbnail (scaled down for picker)

struct VerseCardThumbnail: View {
    let template: CardTemplate

    var body: some View {
        ZStack {
            if let gradient = template.backgroundGradient {
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                template.backgroundColor
            }

            // Show sample text
            VStack(spacing: 4) {
                Text("Abc")
                    .font(.custom(template.fontName, size: 12))
                    .foregroundStyle(template.textColor)
                Text("1:1")
                    .font(.system(size: 8))
                    .foregroundStyle(template.referenceColor)
            }
        }
        .frame(width: 56, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    VerseCardView(
        verseText: "God is our refuge and strength, a very present help in trouble.",
        verseReference: "Psalm 46:1",
        template: CardTemplate.all[0]
    )
    .scaleEffect(0.2)
}
