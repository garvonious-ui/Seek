import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: String  // Supabase Auth UID
    var displayName: String
    var email: String
    var profileImageURL: String?
    var createdAt: Date
    var isPremium: Bool
    var premiumExpiresAt: Date?
    var onboardingTopics: [String]
    var streakCount: Int
    var longestStreak: Int
    var lastActiveDate: Date?
    var totalVersesExplored: Int
    var totalCardsCreated: Int
    var dailyChatsUsed: Int
    var dailyChatsResetDate: Date

    init(
        id: String,
        displayName: String = "",
        email: String = "",
        profileImageURL: String? = nil,
        createdAt: Date = .now,
        isPremium: Bool = false,
        premiumExpiresAt: Date? = nil,
        onboardingTopics: [String] = [],
        streakCount: Int = 0,
        longestStreak: Int = 0,
        lastActiveDate: Date? = nil,
        totalVersesExplored: Int = 0,
        totalCardsCreated: Int = 0,
        dailyChatsUsed: Int = 0,
        dailyChatsResetDate: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.isPremium = isPremium
        self.premiumExpiresAt = premiumExpiresAt
        self.onboardingTopics = onboardingTopics
        self.streakCount = streakCount
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
        self.totalVersesExplored = totalVersesExplored
        self.totalCardsCreated = totalCardsCreated
        self.dailyChatsUsed = dailyChatsUsed
        self.dailyChatsResetDate = dailyChatsResetDate
    }
}
