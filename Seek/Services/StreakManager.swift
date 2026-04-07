import Foundation
import SwiftData

/// Handles streak calculation and daily activity tracking
struct StreakManager {

    /// Record that the user was active today and update streak
    @MainActor
    static func recordActivity(modelContext: ModelContext) {
        guard let profile = fetchProfile(modelContext: modelContext) else { return }

        let today = Calendar.current.startOfDay(for: .now)

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
