import WidgetKit
import SwiftUI

// MARK: - Timeline

struct VerseEntry: TimelineEntry {
    let date: Date
    let verse: SharedVerse
}

struct VerseProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, verse: .fallback)
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(VerseEntry(date: .now, verse: WidgetVerseProvider.resolvedVerse(for: .now)))
    }

    /// One entry per day for a week ahead, each flipping at local midnight so
    /// the verse rolls over without the app needing to run. When the app is
    /// opened it writes today's real verse and reloads the timeline.
    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        var entries: [VerseEntry] = []

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
            // The very first entry uses "now" so it appears immediately.
            let entryDate = dayOffset == 0 ? Date.now : day
            entries.append(VerseEntry(date: entryDate, verse: WidgetVerseProvider.resolvedVerse(for: day)))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Entry view

struct DailyVerseEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VerseEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumVerseView(verse: entry.verse)
        case .accessoryRectangular:
            RectangularVerseView(verse: entry.verse)
        case .accessoryInline:
            // System renders this as a single tinted line beside the clock.
            Label(entry.verse.reference, systemImage: "book.closed.fill")
        case .accessoryCircular:
            CircularVerseView(verse: entry.verse)
        default:
            SmallVerseView(verse: entry.verse)
        }
    }
}

// MARK: - Home screen: small

private struct SmallVerseView: View {
    let verse: SharedVerse

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DAILY VERSE")
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(WidgetTheme.gold)

            Text("\u{201C}\(verse.text)\u{201D}")
                .font(.custom("Georgia", size: 13))
                .foregroundStyle(WidgetTheme.textPrimary)
                .lineSpacing(2)
                .minimumScaleFactor(0.7)
                .lineLimit(5)

            Spacer(minLength: 0)

            Text(verse.reference)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WidgetTheme.sage)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { WidgetTheme.background }
    }
}

// MARK: - Home screen: medium

private struct MediumVerseView: View {
    let verse: SharedVerse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DAILY VERSE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(WidgetTheme.gold)
                Spacer()
                Text(verse.theme.capitalized)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(WidgetTheme.gold)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(WidgetTheme.gold.opacity(0.15), in: Capsule())
            }

            Text("\u{201C}\(verse.text)\u{201D}")
                .font(.custom("Georgia", size: 15))
                .foregroundStyle(WidgetTheme.textPrimary)
                .lineSpacing(3)
                .minimumScaleFactor(0.7)
                .lineLimit(4)

            Spacer(minLength: 0)

            Text("\u{2014} \(verse.reference)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(WidgetTheme.sage)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) { WidgetTheme.background }
    }
}

// MARK: - Lock screen: rectangular

private struct RectangularVerseView: View {
    let verse: SharedVerse

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verse.reference)
                .font(.system(size: 13, weight: .bold))
                .widgetAccentable()
            Text(verse.text)
                .font(.custom("Georgia", size: 12))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Lock screen: circular

private struct CircularVerseView: View {
    let verse: SharedVerse

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Seek")
                    .font(.system(size: 9, weight: .medium))
            }
            .widgetAccentable()
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Widget configuration

struct DailyVerseWidget: Widget {
    let kind = "DailyVerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VerseProvider()) { entry in
            DailyVerseEntryView(entry: entry)
                .widgetURL(URL(string: "seek://dailyverse"))
        }
        .configurationDisplayName("Verse of the Day")
        .description("A fresh scripture verse on your Home and Lock Screen each day.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular,
        ])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    DailyVerseWidget()
} timeline: {
    VerseEntry(date: .now, verse: .fallback)
}

#Preview("Medium", as: .systemMedium) {
    DailyVerseWidget()
} timeline: {
    VerseEntry(date: .now, verse: SharedVerse(reference: "Isaiah 40:31", text: "But those who trust in the LORD will find new strength. They will soar high on wings like eagles.", theme: "strength"))
}

#Preview("Rectangular", as: .accessoryRectangular) {
    DailyVerseWidget()
} timeline: {
    VerseEntry(date: .now, verse: .fallback)
}
