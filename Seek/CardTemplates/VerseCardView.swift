import SwiftUI

/// The actual card view that gets rendered to an image
struct VerseCardView: View {
    let verseText: String
    let verseReference: String
    let template: CardTemplate

    // Render dimensions: 1080x1920 (9:16 IG story)
    static let renderWidth: CGFloat = 1080
    static let renderHeight: CGFloat = 1920

    var body: some View {
        ZStack {
            // Background
            if let gradient = template.backgroundGradient {
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                template.backgroundColor
            }

            // Content
            VStack(spacing: 40) {
                Spacer()

                // Verse text
                Text(verseText)
                    .font(.custom(template.fontName, size: fontSize))
                    .lineSpacing(20)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(template.textColor)
                    .padding(.horizontal, 100)

                // Reference
                Text("— \(verseReference)")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(template.referenceColor)

                Spacer()

                // Watermark
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 16))
                    Text("Seek")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundStyle(template.textColor.opacity(0.3))
                .padding(.bottom, 40)
            }
        }
        .frame(width: Self.renderWidth, height: Self.renderHeight)
    }

    /// Auto-size font based on verse length
    private var fontSize: CGFloat {
        let length = verseText.count
        if length < 80 { return 88 }
        if length < 150 { return 72 }
        if length < 250 { return 60 }
        if length < 400 { return 48 }
        return 40
    }
}

// MARK: - Preview thumbnail (scaled down for picker)

struct VerseCardThumbnail: View {
    let template: CardTemplate
    let isPremium: Bool

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

            // Premium lock overlay
            if template.isPremium && !isPremium {
                Color.black.opacity(0.3)
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
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
