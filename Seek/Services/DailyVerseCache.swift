import Foundation

/// Persists the most recently fetched daily verse to UserDefaults so the home
/// screen can render something meaningful when the user is offline.
///
/// This is deliberately tiny — one slot, not a history. The daily-verse
/// endpoint returns a different verse per day anyway, so we only care about
/// "what did we last show the user so we can keep showing it if the network
/// is down."
enum DailyVerseCache {
    private static let key = "cachedDailyVerse.v1"

    /// A cached daily verse plus the date it was fetched so callers can show
    /// the user how fresh (or stale) the offline copy is.
    struct Entry: Codable {
        let verse: DailyVerse
        let fetchedAt: Date
    }

    static func save(_ verse: DailyVerse) {
        let entry = Entry(verse: verse, fetchedAt: .now)
        if let data = try? JSONEncoder().encode(entry) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> Entry? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Entry.self, from: data)
    }
}
