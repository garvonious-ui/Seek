import SwiftUI

/// The shareable weekly recap ("Evening" — verse-led, dark). Laid out in a
/// 540-wide coordinate space and scaled off `renderSize.width`, like
/// VerseCardView, so the 1080x1920 story export and the small preview in
/// WeeklySummaryView are the same layout.
struct WeeklyShareCardView: View {
    let summary: WeeklySummary
    var renderSize: CGSize = CGSize(width: 1080, height: 1920)

    private var s: CGFloat { renderSize.width / 540 }

    private let background = Color(hex: "1F2B22")
    private let cream = Color(hex: "F4EFE3")
    private let muted = Color(hex: "B9C2B5")
    private let gold = Color(hex: "CDA349")
    private let dotOff = Color(hex: "5E6E60")

    /// Shrink long passages so the verse never crowds the stats.
    private var verseSize: CGFloat {
        switch summary.verseText.count {
        case ..<110: 34
        case ..<180: 29
        case ..<260: 25
        default: 22
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8 * s) {
                Text("YOUR WEEK WITH SEEK")
                    .font(.system(size: 12 * s, weight: .semibold))
                    .tracking(2.2 * s)
                    .foregroundStyle(gold)
                Text(summary.dateRange)
                    .font(.system(size: 15 * s))
                    .foregroundStyle(muted)
            }

            Spacer(minLength: 24 * s)

            VStack(spacing: 28 * s) {
                rule
                Text("THE VERSE THAT CARRIED YOUR WEEK")
                    .font(.system(size: 11 * s, weight: .semibold))
                    .tracking(2 * s)
                    .foregroundStyle(muted)
                Text("“\(summary.verseText)”")
                    .font(.custom("Georgia", size: verseSize * s))
                    .lineSpacing(verseSize * 0.4 * s)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(cream)
                    .minimumScaleFactor(0.7)
                Text(summary.verseReference)
                    .font(.system(size: 15 * s, weight: .semibold))
                    .tracking(0.6 * s)
                    .foregroundStyle(gold)
                rule
            }

            Spacer(minLength: 24 * s)

            VStack(spacing: 22 * s) {
                VStack(spacing: 12 * s) {
                    HStack(spacing: 10 * s) {
                        ForEach(Array(summary.activeDays.enumerated()), id: \.offset) { _, active in
                            Circle()
                                .fill(active ? gold : .clear)
                                .overlay(Circle().strokeBorder(active ? .clear : dotOff, lineWidth: 1.5 * s))
                                .frame(width: 14 * s, height: 14 * s)
                        }
                    }
                    Text("\(summary.daysActive) of 7 days in the Word")
                        .font(.system(size: 16 * s))
                        .foregroundStyle(cream)
                }

                HStack(spacing: 14 * s) {
                    stat(summary.versesExplored, "verse", "verses")
                    separator
                    stat(summary.prayersSaved, "prayer", "prayers")
                    separator
                    stat(summary.cardsMade, "card", "cards")
                }

                if !summary.themes.isEmpty {
                    Text("On your heart: \(summary.themes.map { $0.lowercased() }.joined(separator: ", "))")
                        .font(.system(size: 14 * s))
                        .foregroundStyle(muted)
                }

                VStack(spacing: 2 * s) {
                    Text("Seek")
                        .font(.custom("Georgia", size: 26 * s))
                        .foregroundStyle(gold)
                    Text("askseekpray.app")
                        .font(.system(size: 12 * s))
                        .foregroundStyle(Color(hex: "8E9A8B"))
                }
                .padding(.top, 10 * s)
            }
        }
        .padding(.top, 56 * s)
        .padding(.horizontal, 48 * s)
        .padding(.bottom, 40 * s)
        .frame(width: renderSize.width, height: renderSize.height)
        .background(background)
    }

    private var rule: some View {
        Rectangle().fill(gold).frame(width: 48 * s, height: max(1, s))
    }

    private var separator: some View {
        Text("·").font(.system(size: 15 * s)).foregroundStyle(dotOff)
    }

    private func stat(_ value: Int, _ singular: String, _ plural: String) -> some View {
        Text("\(value)").font(.custom("Georgia", size: 22 * s)).foregroundColor(cream)
            + Text(" \(value == 1 ? singular : plural)").font(.system(size: 15 * s)).foregroundColor(muted)
    }
}

#Preview {
    WeeklyShareCardView(summary: .sample, renderSize: CGSize(width: 360, height: 640))
}
