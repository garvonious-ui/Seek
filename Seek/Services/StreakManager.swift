import Foundation
import SwiftData

/// Handles streak calculation and daily activity tracking
struct StreakManager {

    /// Record that the user was active today and update streak
    @MainActor
    static func recordActivity(modelContext: ModelContext) {
        guard let profile = fetchProfile(modelContext: modelContext) else { return }

        let today = Calendar.current.startOfDay(for: .now)
        recordActiveDay(today)

        // Already recorded today
        if let lastActive = profile.lastActiveDate,
           Calendar.current.isDate(lastActive, inSameDayAs: today) {
            return
        }

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        if let lastActive = profile.lastActiveDate {
            if Calendar.current.isDate(lastActive, inSameDayAs: yesterday) {
                // Consecutive day — increment streak
                profile.streakCount += 1
            } else {
                // Check grace period: missed exactly one day
                let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
                if Calendar.current.isDate(lastActive, inSameDayAs: twoDaysAgo) {
                    // Grace period — keep streak but don't increment (need 2 actions today)
                    // For now, just keep the streak
                    profile.streakCount += 1
                } else {
                    // Streak broken
                    profile.streakCount = 1
                }
            }
        } else {
            // First activity ever
            profile.streakCount = 1
        }

        // Update longest streak
        if profile.streakCount > profile.longestStreak {
            profile.longestStreak = profile.streakCount
        }

        profile.lastActiveDate = today

        // Reset daily chat count if new day
        if !Calendar.current.isDate(profile.dailyChatsResetDate, inSameDayAs: today) {
            profile.dailyChatsUsed = 0
            profile.dailyChatsResetDate = today
        }

        try? modelContext.save()
    }

    // MARK: - Active-day log
    //
    // The profile only keeps lastActiveDate + a running streak, which can't
    // answer "which days this week?". The weekly summary reads this log
    // (plus timestamps on chats, favorites, prayers and cards for days before
    // the log existed). Day keys are local-calendar "yyyy-MM-dd".

    private static let activeDaysKey = "activeDayKeys"
    private static let activeDaysRetention = 70

    static func dayKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func recordActiveDay(_ date: Date = .now) {
        var keys = Set(UserDefaults.standard.stringArray(forKey: activeDaysKey) ?? [])
        keys.insert(dayKey(date))
        // Keys sort chronologically as strings; keep the most recent ~10 weeks.
        let trimmed = keys.sorted().suffix(activeDaysRetention)
        UserDefaults.standard.set(Array(trimmed), forKey: activeDaysKey)
    }

    static var activeDayKeys: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: activeDaysKey) ?? [])
    }

    /// Check if user hit a milestone
    static func checkMilestone(streakCount: Int) -> Int? {
        let milestones = [7, 30, 90, 365]
        return milestones.contains(streakCount) ? streakCount : nil
    }

    // MARK: - Private

    @MainActor
    private static func fetchProfile(modelContext: ModelContext) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try? modelContext.fetch(descriptor).first
    }
}
