package com.loucesario.seek.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Upsert
import com.loucesario.seek.data.local.entity.ChatConversationEntity
import com.loucesario.seek.data.local.entity.ChatMessageEntity
import com.loucesario.seek.data.local.entity.FavoriteVerseEntity
import com.loucesario.seek.data.local.entity.SavedCardEntity
import com.loucesario.seek.data.local.entity.SavedPrayerEntity
import com.loucesario.seek.data.local.entity.UserProfileEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface UserProfileDao {
    @Upsert
    suspend fun upsert(profile: UserProfileEntity)

    @Query("SELECT * FROM user_profile WHERE id = :id")
    fun observe(id: String): Flow<UserProfileEntity?>

    @Query("SELECT * FROM user_profile WHERE id = :id")
    suspend fun get(id: String): UserProfileEntity?

    @Query("DELETE FROM user_profile WHERE id = :id")
    suspend fun delete(id: String)
}

@Dao
interface SavedCardDao {
    @Upsert
    suspend fun upsert(card: SavedCardEntity)

    @Query("SELECT * FROM saved_card ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<SavedCardEntity>>

    /** Cards made in [start, end) epoch-millis — the weekly summary. */
    @Query("SELECT * FROM saved_card WHERE createdAt >= :start AND createdAt < :end")
    suspend fun createdBetween(start: Long, end: Long): List<SavedCardEntity>

    @Delete
    suspend fun delete(card: SavedCardEntity)
}

@Dao
interface FavoriteVerseDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(verse: FavoriteVerseEntity)

    @Query("SELECT * FROM favorite_verse ORDER BY savedAt DESC")
    fun observeAll(): Flow<List<FavoriteVerseEntity>>

    /** Favorites saved in [start, end) epoch-millis, newest first — the weekly summary. */
    @Query("SELECT * FROM favorite_verse WHERE savedAt >= :start AND savedAt < :end ORDER BY savedAt DESC")
    suspend fun savedBetween(start: Long, end: Long): List<FavoriteVerseEntity>

    @Query("DELETE FROM favorite_verse WHERE reference = :reference")
    suspend fun deleteByReference(reference: String)

    @Delete
    suspend fun delete(verse: FavoriteVerseEntity)
}

@Dao
interface SavedPrayerDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(prayer: SavedPrayerEntity)

    @Query("SELECT * FROM saved_prayer ORDER BY savedAt DESC")
    fun observeAll(): Flow<List<SavedPrayerEntity>>

    /** Prayers saved in [start, end) epoch-millis — the weekly summary. */
    @Query("SELECT * FROM saved_prayer WHERE savedAt >= :start AND savedAt < :end")
    suspend fun savedBetween(start: Long, end: Long): List<SavedPrayerEntity>

    @Query("DELETE FROM saved_prayer WHERE text = :text")
    suspend fun deleteByText(text: String)

    @Delete
    suspend fun delete(prayer: SavedPrayerEntity)
}

@Dao
interface ChatDao {
    @Upsert
    suspend fun upsertConversation(conversation: ChatConversationEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: ChatMessageEntity)

    @Transaction
    @Query("SELECT * FROM chat_conversation ORDER BY startedAt DESC")
    fun observeConversations(): Flow<List<ConversationWithMessages>>

    @Transaction
    @Query("SELECT * FROM chat_conversation WHERE id = :id")
    suspend fun getConversation(id: String): ConversationWithMessages?

    @Query("DELETE FROM chat_conversation WHERE id = :id")
    suspend fun deleteConversation(id: String)

    /** Messages (all conversations) sent in [start, end) epoch-millis, oldest first — the weekly summary. */
    @Query("SELECT * FROM chat_message WHERE timestamp >= :start AND timestamp < :end ORDER BY timestamp")
    suspend fun messagesBetween(start: Long, end: Long): List<ChatMessageEntity>
}
