package com.loucesario.seek.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Upsert
import com.loucesario.seek.data.local.entity.ChatConversationEntity
import com.loucesario.seek.data.local.entity.ChatMessageEntity
import com.loucesario.seek.data.local.entity.FavoriteVerseEntity
import com.loucesario.seek.data.local.entity.SavedCardEntity
import com.loucesario.seek.data.local.entity.SavedPrayerEntity
import com.loucesario.seek.data.local.entity.SyncTombstoneEntity

/**
 * Everything cloud sync needs from Room, kept apart from the feature DAOs.
 * Pull writes use @Upsert (insert-or-update, never delete+insert) — a REPLACE
 * on chat_conversation would cascade-delete its messages.
 */
@Dao
interface SyncDao {
    // Dirty rows (push)
    @Query("SELECT * FROM chat_conversation WHERE needsSync = 1") suspend fun dirtyConversations(): List<ChatConversationEntity>
    @Query("SELECT * FROM chat_message WHERE needsSync = 1") suspend fun dirtyMessages(): List<ChatMessageEntity>
    @Query("SELECT * FROM saved_card WHERE needsSync = 1") suspend fun dirtyCards(): List<SavedCardEntity>
    @Query("SELECT * FROM favorite_verse WHERE needsSync = 1") suspend fun dirtyFavorites(): List<FavoriteVerseEntity>
    @Query("SELECT * FROM saved_prayer WHERE needsSync = 1") suspend fun dirtyPrayers(): List<SavedPrayerEntity>

    @Query("UPDATE chat_conversation SET needsSync = 0 WHERE id IN (:ids)") suspend fun cleanConversations(ids: List<String>)
    @Query("UPDATE chat_message SET needsSync = 0 WHERE id IN (:ids)") suspend fun cleanMessages(ids: List<String>)
    @Query("UPDATE saved_card SET needsSync = 0 WHERE id IN (:ids)") suspend fun cleanCards(ids: List<String>)
    @Query("UPDATE favorite_verse SET needsSync = 0 WHERE id IN (:ids)") suspend fun cleanFavorites(ids: List<String>)
    @Query("UPDATE saved_prayer SET needsSync = 0 WHERE id IN (:ids)") suspend fun cleanPrayers(ids: List<String>)

    @Query(
        "SELECT (SELECT COUNT(*) FROM chat_conversation WHERE needsSync = 1) + " +
            "(SELECT COUNT(*) FROM chat_message WHERE needsSync = 1) + " +
            "(SELECT COUNT(*) FROM saved_card WHERE needsSync = 1) + " +
            "(SELECT COUNT(*) FROM favorite_verse WHERE needsSync = 1) + " +
            "(SELECT COUNT(*) FROM saved_prayer WHERE needsSync = 1) + " +
            "(SELECT COUNT(*) FROM sync_tombstone)"
    )
    suspend fun pendingCount(): Int

    // Lookups (pull)
    @Query("SELECT * FROM chat_conversation WHERE id = :id") suspend fun conversation(id: String): ChatConversationEntity?
    @Query("SELECT id FROM chat_message WHERE id = :id") suspend fun messageId(id: String): String?
    @Query("SELECT * FROM saved_card WHERE id = :id") suspend fun card(id: String): SavedCardEntity?
    @Query("SELECT id FROM favorite_verse WHERE id = :id") suspend fun favoriteId(id: String): String?
    @Query("SELECT id FROM saved_prayer WHERE id = :id") suspend fun prayerId(id: String): String?

    @Upsert suspend fun upsertConversation(row: ChatConversationEntity)
    @Upsert suspend fun upsertMessage(row: ChatMessageEntity)
    @Upsert suspend fun upsertCard(row: SavedCardEntity)
    @Upsert suspend fun upsertFavorite(row: FavoriteVerseEntity)
    @Upsert suspend fun upsertPrayer(row: SavedPrayerEntity)

    @Query("DELETE FROM chat_conversation WHERE id = :id") suspend fun deleteConversation(id: String)
    @Query("DELETE FROM chat_message WHERE id = :id") suspend fun deleteMessage(id: String)
    @Query("DELETE FROM saved_card WHERE id = :id") suspend fun deleteCard(id: String)
    @Query("DELETE FROM favorite_verse WHERE id = :id") suspend fun deleteFavorite(id: String)
    @Query("DELETE FROM saved_prayer WHERE id = :id") suspend fun deletePrayer(id: String)

    // Tombstones
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun insertTombstones(rows: List<SyncTombstoneEntity>)
    @Query("SELECT * FROM sync_tombstone") suspend fun tombstones(): List<SyncTombstoneEntity>
    @Query("DELETE FROM sync_tombstone WHERE id IN (:ids)") suspend fun deleteTombstones(ids: List<String>)

    @Query("SELECT id FROM favorite_verse WHERE reference = :reference") suspend fun favoriteIdsByReference(reference: String): List<String>
    @Query("SELECT id FROM saved_prayer WHERE text = :text") suspend fun prayerIdsByText(text: String): List<String>

    // Sign-out / account switch
    @Query("DELETE FROM chat_message") suspend fun clearMessages()
    @Query("DELETE FROM chat_conversation") suspend fun clearConversations()
    @Query("DELETE FROM saved_card") suspend fun clearCards()
    @Query("DELETE FROM favorite_verse") suspend fun clearFavorites()
    @Query("DELETE FROM saved_prayer") suspend fun clearPrayers()
    @Query("DELETE FROM sync_tombstone") suspend fun clearTombstones()
}
