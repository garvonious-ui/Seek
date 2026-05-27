package com.loucesario.seek.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Room entities mirroring the iOS SwiftData models in docs/schemas.md.
 * Dates are epoch-millis Longs. IDs are Strings (UUID/Supabase UID as text).
 */

@Entity(tableName = "user_profile")
data class UserProfileEntity(
    @PrimaryKey val id: String, // Supabase Auth UID
    val displayName: String = "",
    val email: String = "",
    val profileImageUrl: String? = null,
    val createdAt: Long = 0L,
    val isPremium: Boolean = false,
    val premiumExpiresAt: Long? = null,
    val onboardingTopics: List<String> = emptyList(),
    val streakCount: Int = 0,
    val longestStreak: Int = 0,
    val lastActiveDate: Long? = null,
    val totalVersesExplored: Int = 0,
    val totalCardsCreated: Int = 0,
    val dailyChatsUsed: Int = 0,
    val dailyChatsResetDate: Long = 0L,
    val preferredTranslation: String = "NLT",
)

@Entity(tableName = "saved_card")
data class SavedCardEntity(
    @PrimaryKey val id: String,
    val verseReference: String,
    val verseText: String,
    val templateId: String,
    val createdAt: Long,
    val isFavorite: Boolean = false,
    val contextNote: String? = null,
)

@Entity(tableName = "chat_conversation")
data class ChatConversationEntity(
    @PrimaryKey val id: String,
    val startedAt: Long,
    val summary: String? = null,
)

@Entity(
    tableName = "chat_message",
    foreignKeys = [
        ForeignKey(
            entity = ChatConversationEntity::class,
            parentColumns = ["id"],
            childColumns = ["conversationId"],
            onDelete = ForeignKey.CASCADE,
        )
    ],
    indices = [Index("conversationId")],
)
data class ChatMessageEntity(
    @PrimaryKey val id: String,
    val conversationId: String,
    val role: String, // "user" | "assistant"
    val content: String, // raw text for user, JSON for assistant
    val timestamp: Long,
)

@Entity(tableName = "favorite_verse")
data class FavoriteVerseEntity(
    @PrimaryKey val id: String,
    val reference: String,
    val text: String,
    val savedAt: Long,
    val source: String, // "chat" | "daily_verse"
)

@Entity(tableName = "saved_prayer")
data class SavedPrayerEntity(
    @PrimaryKey val id: String,
    val text: String,
    val contextNote: String? = null, // the prompt that produced it
    val savedAt: Long,
)
