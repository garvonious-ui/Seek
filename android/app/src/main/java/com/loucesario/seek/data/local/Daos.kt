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

    @Delete
    suspend fun delete(card: SavedCardEntity)
}

@Dao
interface FavoriteVerseDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(verse: FavoriteVerseEntity)

    @Query("SELECT * FROM favorite_verse ORDER BY savedAt DESC")
    fun observeAll(): Flow<List<FavoriteVerseEntity>>

    @Delete
    suspend fun delete(verse: FavoriteVerseEntity)
}

@Dao
interface SavedPrayerDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(prayer: SavedPrayerEntity)

    @Query("SELECT * FROM saved_prayer ORDER BY savedAt DESC")
    fun observeAll(): Flow<List<SavedPrayerEntity>>

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
}
