import SwiftUI

/// The in-app weekly recap ("Morning" — stats-led, light). Sharing renders
/// the dark, verse-led WeeklyShareCardView as a 1080x1920 story image.
struct WeeklySummaryView: View {
    let summary: WeeklySummary
    @Environment(\.dismiss) private var dismiss
    @State private var shareTarget: SharedImage?

    private struct SharedImage: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    private let sage = Color(hex: "5B7B5E")
    private let darkGold = Color(hex: "7A5C17")
    private let gray = Color(hex: "6B7280")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("YOUR WEEK WITH SEEK")
                            .font(.caption.weight(.semibold))
                            .tracking(1.8)
                            .foregroundStyle(sage)
                        Text(summary.dateRange)
                            .font(.subheadline)
                            .foregroundStyle(gray)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(summary.daysActive)")
                                .font(.custom("Georgia", size: 104))
                            Text(summary.daysActive == 1 ? "day" : "days")
                                .font(.custom("Georgia", size: 34))
                        }
                        .foregroundStyle(Color(hex: "1A1A1A"))
                        Text("spent in the Word this week")
                            .font(.body)
                            .foregroundStyle(Color(hex: "4B5563"))
                    }
                    .accessibilityElement(children: .combine)

                    VStack(alignment: .leading, spacing: 14) {
                        dayDots
                        Label(streakLine, systemImage: "flame")
                            .font(.subheadline)
                            .foregroundStyle(darkGold)
                            .labelStyle(GoldIconLabelStyle())
                    }

                    verseCard

                    HStack(alignment: .top, spacing: 12) {
                        stat(summary.versesExplored, "verse explored", "verses explored")
                        stat(summary.prayersSaved, "prayer saved", "prayers saved")
                        stat(summary.cardsMade, "card made", "cards made")
                    }

                    if !summary.themes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WHAT WAS ON YOUR HEART")
                                .font(.caption2.weight(.semibold))
                                .tracking(1.6)
                                .foregroundStyle(gray)
                            HStack(spacing: 8) {
                                ForEach(summary.themes, id: \.self) { theme in
                                    Text(theme)
                                        .font(.subheadline)
                                        .foregroundStyle(Color(hex: "3F5A42"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(sage.opacity(0.12), in: Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(hex: "FAF7F0"))
            .safeAreaInset(edge: .bottom) { shareBar }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(sage)
                }
            }
        }
        .sheet(item: $shareTarget) { target in
            ShareSheetView(image: target.image)
        }
    }

    // MARK: - Pieces

    private var streakLine: String {
        if summary.isQuiet { return "Every moment counts. Pick up where you left off." }
        let streak = "\(summary.streak)-day streak"
        if summary.streak >= summary.longestStreak { return "\(streak) — your longest yet" }
        return "\(streak) — your longest is \(summary.longestStreak)"
    }

    private var dayDots: some View {
        HStack(spacing: 8) {
            ForEach(Array(zip(["M", "T", "W", "T", "F", "S", "S"], summary.activeDays).enumerated()), id: \.offset) { _, day in
                let (letter, active) = day
                Text(letter)
                    .font(.subheadline.weight(active ? .semibold : .regular))
                    .foregroundStyle(active ? .white : Color(hex: "9CA3AF"))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background {
                        if active {
                            Circle().fill(sage)
                        } else {
                            Circle().strokeBorder(Color(hex: "D5D9D0"), lineWidth: 1.5)
                        }
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(summary.daysActive) of 7 days active this week")
    }

    private var verseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THE VERSE YOU HELD ONTO")
                .font(.caption2.weight(.semibold))
                .tracking(1.6)
                .foregroundStyle(darkGold)
            Text(summary.verseText)
                .font(.custom("Georgia", size: 20))
                .lineSpacing(6)
                .foregroundStyle(Color(hex: "1A1A1A"))
            HStack {
                Text("— \(summary.verseReference)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(sage)
                Spacer()
                CopyButton(text: CopyButton.verseText(summary.verseText, reference: summary.verseReference))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func stat(_ value: Int, _ singular: String, _ plural: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.custom("Georgia", size: 34))
                .foregroundStyle(Color(hex: "1A1A1A"))
            Text(value == 1 ? singular : plural)
                .font(.footnote)
                .foregroundStyle(gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var shareBar: some View {
        HStack(spacing: 14) {
            WeeklyShareCardView(summary: summary, renderSize: CGSize(width: 45, height: 80))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityHidden(true)
            Button {
                if let image = renderShareImage() {
                    shareTarget = SharedImage(image: image)
                }
            } label: {
                Label("Share your week", systemImage: "square.and.arrow.up")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(sage)
            .controlSize(.large)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.bar)
    }

    @MainActor
    private func renderShareImage() -> UIImage? {
        let renderer = ImageRenderer(content: WeeklyShareCardView(summary: summary))
        renderer.scale = 1 // laid out at 1080x1920 points -> exact story size
        return renderer.uiImage
    }
}

/// Gold flame icon with the label's own (darker, readable) text color.
private struct GoldIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.foregroundStyle(Color(hex: "CDA349"))
            configuration.title
        }
    }
}

#if DEBUG
#Preview {
    WeeklySummaryView(summary: .sample)
}
#endif
