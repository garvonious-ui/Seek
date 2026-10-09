import Foundation
import SwiftData

/// One week's recap (Mon–Sun, local calendar) for the Weekly Summary card.
/// Built entirely from on-device data — nothing new is sent to the server.
struct WeeklySummary: Identifiable, Equatable {
    let weekStart: Date
    /// Mon…Sun.
    let activeDays: [Bool]
    let versesExplored: Int
    let prayersSaved: Int
    let cardsMade: Int
    /// Up to three, most-mentioned first.
    let themes: [String]
    let verseText: String
    let verseReference: String
    let streak: Int
    let longestStreak: Int

    var id: String { StreakManager.dayKey(weekStart) }
    var daysActive: Int { activeDays.filter { $0 }.count }
    /// A light week gets encouragement instead of a streak brag.
    var isQuiet: Bool { daysActive <= 2 }

    var dateRange: String {
        let end = WeeklySummaryBuilder.calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let month = DateFormatter()
        month.setLocalizedDateFormatFromTemplate("MMMd")
        let day = DateFormatter()
        day.setLocalizedDateFormatFromTemplate("d")
        let sameMonth = Calendar.current.isDate(weekStart, equalTo: end, toGranularity: .month)
        return "\(month.string(from: weekStart)) – \(sameMonth ? day.string(from: end) : month.string(from: end))"
    }
}

enum WeeklySummaryBuilder {
    /// Weeks run Monday–Sunday regardless of locale, to match the card's M…S row.
    static var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }

    static func weekStart(containing date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// The week the Home tile offers right now: this week from Sunday noon,
    /// last week on Monday and Tuesday, otherwise none.
    static func recapWeekStart(now: Date = .now) -> Date? {
        let comps = Calendar.current.dateComponents([.weekday, .hour], from: now)
        switch comps.weekday {
        case 1 where (comps.hour ?? 0) >= 12:
            return weekStart(containing: now)
        case 2, 3:
            return calendar.date(byAdding: .day, value: -7, to: weekStart(containing: now))
        default:
            return nil
        }
    }

    @MainActor
    static func build(weekStart start: Date, modelContext: ModelContext) -> WeeklySummary {
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start

        let messages = (try? modelContext.fetch(FetchDescriptor<ChatMessage>(
            predicate: #Predicate { $0.timestamp >= start && $0.timestamp < end },
            sortBy: [SortDescriptor(\.timestamp)]
        ))) ?? []
        let favorites = (try? modelContext.fetch(FetchDescriptor<FavoriteVerse>(
            predicate: #Predicate { $0.savedAt >= start && $0.savedAt < end },
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        ))) ?? []
        let prayers = (try? modelContext.fetch(FetchDescriptor<SavedPrayer>(
            predicate: #Predicate { $0.savedAt >= start && $0.savedAt < end }
        ))) ?? []
        let cards = (try? modelContext.fetch(FetchDescriptor<SavedCard>(
            predicate: #Predicate { $0.createdAt >= start && $0.createdAt < end }
        ))) ?? []
        let profile = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first

        let userMessages = messages.filter { $0.role == "user" }
        let responses: [ChatResponse] = messages
            .filter { $0.role == "assistant" }
            .compactMap { $0.content.data(using: .utf8) }
            .compactMap { try? JSONDecoder().decode(ChatResponse.self, from: $0) }

        // Days in the Word: the active-day log, plus timestamps on what the
        // user did (covers weeks from before the log existed).
        var activeKeys = StreakManager.activeDayKeys
        let stamps = userMessages.map(\.timestamp) + favorites.map(\.savedAt)
            + prayers.map(\.savedAt) + cards.map(\.createdAt)
        stamps.forEach { activeKeys.insert(StreakManager.dayKey($0)) }
        let activeDays = (0..<7).map { offset -> Bool in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return false }
            return activeKeys.contains(StreakManager.dayKey(day))
        }

        // The verse that carried the week: the latest one they favorited,
        // else the latest one Seek gave them, else the daily verse.
        let featured: (text: String, reference: String) = {
            if let fav = favorites.first { return (fav.text, fav.reference) }
            if let verse = responses.last(where: { !$0.verses.isEmpty })?.verses.first {
                return (verse.text, verse.reference)
            }
            if let daily = DailyVerseCache.load()?.verse { return (daily.text, daily.reference) }
            return ("God is our refuge and strength, a very present help in trouble.", "Psalm 46:1")
        }()

        return WeeklySummary(
            weekStart: start,
            activeDays: activeDays,
            versesExplored: responses.reduce(0) { $0 + $1.verses.count },
            prayersSaved: prayers.count,
            cardsMade: cards.count,
            themes: themes(in: userMessages.map(\.content)),
            verseText: featured.text,
            verseReference: featured.reference,
            streak: profile?.streakCount ?? 0,
            longestStreak: profile?.longestStreak ?? 0
        )
    }

    // MARK: - Themes

    /// Plain keyword matching on the user's own messages, on-device. The raw
    /// messages never appear on the card — only these theme names do.
    private static let themeKeywords: [(name: String, words: [String])] = [
        ("Anxiety", ["anxious", "anxiety", "worry", "worried", "stress", "overwhelm", "panic"]),
        ("Fear", ["fear", "afraid", "scared", "terrified"]),
        ("Grief", ["grief", "grieving", "mourning", "passed away", "funeral", "lost my"]),
        ("Loneliness", ["lonely", "loneliness", "alone", "isolated"]),
        ("Gratitude", ["gratitude", "grateful", "thankful", "blessed"]),
        ("Joy", ["joy", "happy", "celebrat"]),
        ("Rest", ["weariness", "weary", "tired", "exhausted", "burned out", "burnt out", "rest"]),
        ("Doubt", ["doubt", "unsure", "questioning"]),
        ("Anger", ["anger", "angry", "furious", "resent"]),
        ("Temptation", ["temptation", "tempted", "addiction"]),
        ("Hope", ["hope", "hopeless", "despair"]),
        ("Forgiveness", ["forgive", "forgiveness", "guilt", "guilty", "shame"]),
        ("Healing", ["healing", "sick", "illness", "surgery", "diagnos", "pain"]),
        ("Guidance", ["guidance", "decision", "direction", "purpose", "what should i"]),
        ("Relationships", ["marriage", "husband", "wife", "relationship", "family", "friendship"]),
    ]

    static func themes(in texts: [String]) -> [String] {
        var counts: [String: Int] = [:]
        for text in texts {
            let lower = text.lowercased()
            for theme in themeKeywords where theme.words.contains(where: { lower.contains($0) }) {
                counts[theme.name, default: 0] += 1
            }
        }
        let order = Dictionary(uniqueKeysWithValues: themeKeywords.enumerated().map { ($1.name, $0) })
        return counts
            .sorted { $0.value != $1.value ? $0.value > $1.value : order[$0.key, default: 0] < order[$1.key, default: 0] }
            .prefix(3)
            .map(\.key)
    }
}

#if DEBUG
extension WeeklySummary {
    static let sample = WeeklySummary(
        weekStart: WeeklySummaryBuilder.weekStart(containing: .now),
        activeDays: [true, true, false, true, true, true, true],
        versesExplored: 23,
        prayersSaved: 4,
        cardsMade: 2,
        themes: ["Anxiety", "Gratitude", "Rest"],
        verseText: "Come unto me, all ye that labour and are heavy laden, and I will give you rest.",
        verseReference: "Matthew 11:28",
        streak: 4,
        longestStreak: 12
    )
}
#endif
