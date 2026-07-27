import Foundation

/// A scripture verse shared between the Seek app and the Verse of the Day
/// widget. Intentionally tiny and self-contained so it can live in the
/// `Shared/` group that compiles into both the app and the widget extension.
struct SharedVerse: Codable, Hashable {
    let reference: String
    let text: String
    let theme: String

    /// Evergreen fallback so nothing ever renders empty — mirrors the inline
    /// fallback used on the Home screen.
    static let fallback = SharedVerse(
        reference: "Psalm 46:1",
        text: "God is our refuge and strength, always ready to help in times of trouble.",
        theme: "strength"
    )
}

/// App Group bridge. The main app writes whatever verse it most recently
/// fetched/showed here; the widget reads it so the two stay in sync. Both
/// targets carry the `group.com.loucesario.seek` App Group entitlement.
enum SharedVerseStore {
    static let appGroupID = "group.com.loucesario.seek"

    private static let verseKey = "widget.dailyVerse.v1"
    private static let dateKey = "widget.dailyVerse.date.v1"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    /// Persist the verse the app is currently showing, stamped with the day it
    /// belongs to so the widget can tell "today's pick" from a stale one.
    static func save(_ verse: SharedVerse, date: Date = .now) {
        guard let defaults, let data = try? JSONEncoder().encode(verse) else { return }
        defaults.set(data, forKey: verseKey)
        defaults.set(Calendar.current.startOfDay(for: date), forKey: dateKey)
    }

    /// The app-written verse plus the day it was written for, if any.
    static func load() -> (verse: SharedVerse, date: Date)? {
        guard let defaults,
              let data = defaults.data(forKey: verseKey),
              let verse = try? JSONDecoder().decode(SharedVerse.self, from: data) else { return nil }
        let date = defaults.object(forKey: dateKey) as? Date ?? .distantPast
        return (verse, date)
    }
}

/// Picks a verse for a given day. Prefers the verse the app wrote for *today*
/// (so the widget matches what the user sees in-app); otherwise falls back to a
/// deterministic-by-date pick from a bundled pool so a fresh install — or an
/// app the user hasn't opened in a while — still shows a fresh verse every day
/// with zero network.
enum WidgetVerseProvider {
    /// The bundled verse pool, loaded once. Lives in the widget extension's
    /// resources (`daily_verses.json`), so `Bundle.main` resolves it inside the
    /// widget process.
    static let pool: [SharedVerse] = {
        guard let url = Bundle.main.url(forResource: "daily_verses", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let verses = try? JSONDecoder().decode([SharedVerse].self, from: data),
              !verses.isEmpty else {
            return [SharedVerse.fallback]
        }
        return verses
    }()

    /// Deterministic pick: same verse all day, rolls over at local midnight,
    /// cycles through the whole pool before repeating.
    static func deterministicVerse(for date: Date) -> SharedVerse {
        guard !pool.isEmpty else { return .fallback }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let dayNumber = Int(startOfDay.timeIntervalSince1970 / 86_400)
        let index = ((dayNumber % pool.count) + pool.count) % pool.count
        return pool[index]
    }

    /// The verse to render for `date`: app-shared if it's for the same day,
    /// else the deterministic fallback.
    static func resolvedVerse(for date: Date = .now) -> SharedVerse {
        if let stored = SharedVerseStore.load(),
           Calendar.current.isDate(stored.date, inSameDayAs: date) {
            return stored.verse
        }
        return deterministicVerse(for: date)
    }
}
