package com.loucesario.seek.data

import android.content.Context
import android.util.Log
import com.loucesario.seek.data.local.SeekDatabase
import com.loucesario.seek.data.local.entity.ChatConversationEntity
import com.loucesario.seek.data.local.entity.ChatMessageEntity
import com.loucesario.seek.data.local.entity.FavoriteVerseEntity
import com.loucesario.seek.data.local.entity.SavedCardEntity
import com.loucesario.seek.data.local.entity.SavedPrayerEntity
import com.loucesario.seek.data.local.entity.SyncTombstoneEntity
import com.loucesario.seek.data.remote.SupabaseModule
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.Instant
import java.time.OffsetDateTime

/**
 * Cloud sync for saved cards, favorite verses, saved prayers and chat history —
 * the Android half of iOS `SyncService`, against the same Supabase tables (so
 * content follows the account across platforms). See ../docs/cloud-sync.md.
 *
 * Push: rows with needsSync = 1 are upserted, then each tombstone marks its
 * remote row deleted_at. Pull: rows changed since the per-table cursor are
 * applied; a row with unpushed local edits is left alone. Deletes always win.
 */
class SyncRepository(appContext: Context, private val db: SeekDatabase) {
    private val dao = db.syncDao()
    private val prefs = appContext.getSharedPreferences("seek_sync", Context.MODE_PRIVATE)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val mutex = Mutex()
    private var debounceJob: Job? = null

    /** Call after any local write; bursts (a chat reply) coalesce into one sync. */
    fun requestSync() {
        debounceJob?.cancel()
        debounceJob = scope.launch {
            delay(1_500)
            syncNow()
        }
    }

    /** Push then pull. False if signed out or anything failed — dirty rows stay dirty and retry next time. */
    suspend fun syncNow(): Boolean = mutex.withLock {
        val userId = SupabaseModule.client.auth.currentUserOrNull()?.id ?: return@withLock false
        runCatching {
            claimLocalData(userId)
            push()
            pull(userId)
        }.onFailure { Log.w(TAG, "sync failed", it) }.isSuccess
    }

    suspend fun hasPendingChanges(): Boolean = dao.pendingCount() > 0

    // ---------------------------------------------------------------- local deletes

    suspend fun deleteCard(id: String) {
        dao.insertTombstones(listOf(SyncTombstoneEntity(id, "saved_cards")))
        dao.deleteCard(id)
        requestSync()
    }

    suspend fun deleteFavoritesByReference(reference: String) {
        val ids = dao.favoriteIdsByReference(reference)
        dao.insertTombstones(ids.map { SyncTombstoneEntity(it, "favorite_verses") })
        ids.forEach { dao.deleteFavorite(it) }
        requestSync()
    }

    suspend fun deletePrayersByText(text: String) {
        val ids = dao.prayerIdsByText(text)
        dao.insertTombstones(ids.map { SyncTombstoneEntity(it, "saved_prayers") })
        ids.forEach { dao.deletePrayer(it) }
        requestSync()
    }

    // ---------------------------------------------------------- sign-out / account switch

    /** Wipes this device's library + cursors. Sign-out (after a final push) and delete-account. */
    suspend fun clearLocalData() {
        dao.clearMessages()
        dao.clearConversations()
        dao.clearCards()
        dao.clearFavorites()
        dao.clearPrayers()
        dao.clearTombstones()
        prefs.edit().clear().apply()
    }

    /**
     * The first account to sync on this device adopts the local data (existing
     * users, anything saved as a guest). If a different account signs in later —
     * only possible with data left by a build that didn't clear on sign-out —
     * that data is dropped instead of being uploaded into the wrong account.
     */
    private suspend fun claimLocalData(userId: String) {
        val owner = prefs.getString(OWNER_KEY, null)
        if (owner == userId) return
        if (owner != null) {
            Log.i(TAG, "local data belongs to another account — clearing")
            clearLocalData()
        }
        prefs.edit().putString(OWNER_KEY, userId).apply()
    }

    // ---------------------------------------------------------------------- push

    private suspend fun push() {
        // Conversations before messages: chat_messages has an FK to chat_conversations.
        pushRows("chat_conversations", dao.dirtyConversations(), { it.id }, ::conversationRow, dao::cleanConversations)
        pushRows("chat_messages", dao.dirtyMessages(), { it.id }, ::messageRow, dao::cleanMessages)
        pushRows("saved_cards", dao.dirtyCards(), { it.id }, ::cardRow, dao::cleanCards)
        pushRows("favorite_verses", dao.dirtyFavorites(), { it.id }, ::favoriteRow, dao::cleanFavorites)
        pushRows("saved_prayers", dao.dirtyPrayers(), { it.id }, ::prayerRow, dao::cleanPrayers)

        val tombstones = dao.tombstones()
        for ((table, group) in tombstones.groupBy { it.remoteTable }) {
            for (chunk in group.chunked(CHUNK)) {
                val ids = chunk.map { it.id }
                // A row that never reached the server matches nothing — fine.
                SupabaseModule.client.from(table).update({ set("deleted_at", Instant.now().toString()) }) {
                    filter { isIn("id", ids) }
                }
                dao.deleteTombstones(ids)
            }
        }
    }

    private suspend inline fun <E, reified R : Any> pushRows(
        table: String,
        dirty: List<E>,
        id: (E) -> String,
        toRow: (E) -> R,
        markClean: suspend (List<String>) -> Unit,
    ) {
        for (chunk in dirty.chunked(CHUNK)) {
            SupabaseModule.client.from(table).upsert(chunk.map(toRow)) { onConflict = "id" }
            markClean(chunk.map(id))
        }
        if (dirty.isNotEmpty()) Log.i(TAG, "pushed ${dirty.size} → $table")
    }

    // ---------------------------------------------------------------------- pull

    private suspend fun pull(userId: String) {
        // Conversations first so incoming messages can attach to them.
        pullTable<ConversationPull>("chat_conversations", userId) { r ->
            if (r.deletedAt != null) {
                dao.deleteConversation(r.id) // FK cascade drops its messages
            } else if (dao.conversation(r.id)?.needsSync != true) {
                dao.upsertConversation(
                    ChatConversationEntity(r.id, millis(r.startedAt), r.summary, needsSync = false)
                )
            }
        }
        pullTable<MessagePull>("chat_messages", userId) { r ->
            if (r.deletedAt != null) {
                dao.deleteMessage(r.id)
            } else if (dao.messageId(r.id) == null && dao.conversation(r.conversationId) != null) {
                // Messages are immutable once written — only new ones need applying.
                dao.upsertMessage(
                    ChatMessageEntity(r.id, r.conversationId, r.role, r.content, millis(r.sentAt), needsSync = false)
                )
            }
        }
        pullTable<CardPull>("saved_cards", userId) { r ->
            if (r.deletedAt != null) {
                dao.deleteCard(r.id)
            } else if (dao.card(r.id)?.needsSync != true) {
                dao.upsertCard(
                    SavedCardEntity(
                        id = r.id, verseReference = r.verseReference, verseText = r.verseText,
                        templateId = r.templateId, createdAt = millis(r.createdAt),
                        isFavorite = r.isFavorite, contextNote = r.contextNote, needsSync = false,
                    )
                )
            }
        }
        pullTable<FavoritePull>("favorite_verses", userId) { r ->
            if (r.deletedAt != null) {
                dao.deleteFavorite(r.id)
            } else if (dao.favoriteId(r.id) == null) {
                dao.upsertFavorite(FavoriteVerseEntity(r.id, r.reference, r.text, millis(r.savedAt), r.source, needsSync = false))
            }
        }
        pullTable<PrayerPull>("saved_prayers", userId) { r ->
            if (r.deletedAt != null) {
                dao.deletePrayer(r.id)
            } else if (dao.prayerId(r.id) == null) {
                dao.upsertPrayer(SavedPrayerEntity(r.id, r.text, r.contextNote, millis(r.savedAt), needsSync = false))
            }
        }
    }

    /** Pages through rows changed since this table's cursor, then advances it to the newest updated_at seen. */
    private suspend inline fun <reified R : PulledRow> pullTable(
        table: String,
        userId: String,
        apply: (R) -> Unit,
    ) {
        val cursorKey = "cursor.$userId.$table"
        val stored = prefs.getLong(cursorKey, -1L).takeIf { it >= 0 }
        var newest = stored
        var offset = 0L
        var applied = 0
        while (true) {
            val page = SupabaseModule.client.from(table).select {
                filter {
                    eq("user_id", userId)
                    // Re-read a little behind the cursor: rows committed out of
                    // order are caught next pass, and applying one twice is harmless.
                    if (stored != null) gt("updated_at", Instant.ofEpochMilli(stored - CURSOR_OVERLAP_MS).toString())
                }
                order("updated_at", Order.ASCENDING)
                range(offset, offset + PAGE - 1)
            }.decodeList<R>()
            page.forEach { apply(it) }
            applied += page.size
            page.lastOrNull()?.let { newest = maxOf(newest ?: 0L, millis(it.updatedAt)) }
            if (page.size < PAGE) break
            offset += PAGE
        }
        newest?.let { prefs.edit().putLong(cursorKey, it).apply() }
        if (applied > 0) Log.i(TAG, "pulled $applied ← $table")
    }

    private companion object {
        const val TAG = "SeekSync"
        const val OWNER_KEY = "ownerUserId"
        const val CHUNK = 100
        const val PAGE = 500
        const val CURSOR_OVERLAP_MS = 120_000L

        fun iso(millis: Long): String = Instant.ofEpochMilli(millis).toString()
        fun millis(timestamp: String): Long = OffsetDateTime.parse(timestamp).toInstant().toEpochMilli()

        fun conversationRow(e: ChatConversationEntity) = ConversationPush(e.id, e.summary, iso(e.startedAt))
        fun messageRow(e: ChatMessageEntity) = MessagePush(e.id, e.conversationId, e.role, e.content, iso(e.timestamp))
        fun cardRow(e: SavedCardEntity) =
            CardPush(e.id, e.verseReference, e.verseText, e.templateId, e.isFavorite, e.contextNote, iso(e.createdAt))
        fun favoriteRow(e: FavoriteVerseEntity) = FavoritePush(e.id, e.reference, e.text, e.source, iso(e.savedAt))
        fun prayerRow(e: SavedPrayerEntity) = PrayerPush(e.id, e.text, "chat", e.contextNote, iso(e.savedAt))
    }
}

// ----------------------------------------------------------------- wire rows
// Push rows carry no updated_at / deleted_at: the server stamps the first and
// only tombstones set the second, so a push can never un-delete a row.

private interface PulledRow { val updatedAt: String }

@Serializable private data class CardPush(
    val id: String,
    @SerialName("verse_reference") val verseReference: String,
    @SerialName("verse_text") val verseText: String,
    @SerialName("template_id") val templateId: String,
    @SerialName("is_favorite") val isFavorite: Boolean,
    @SerialName("context_note") val contextNote: String?,
    @SerialName("created_at") val createdAt: String,
)

@Serializable private data class CardPull(
    val id: String,
    @SerialName("verse_reference") val verseReference: String,
    @SerialName("verse_text") val verseText: String,
    @SerialName("template_id") val templateId: String,
    @SerialName("is_favorite") val isFavorite: Boolean,
    @SerialName("context_note") val contextNote: String? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") override val updatedAt: String,
    @SerialName("deleted_at") val deletedAt: String? = null,
) : PulledRow

@Serializable private data class FavoritePush(
    val id: String,
    val reference: String,
    val text: String,
    val source: String,
    @SerialName("saved_at") val savedAt: String,
)

@Serializable private data class FavoritePull(
    val id: String,
    val reference: String,
    val text: String,
    val source: String,
    @SerialName("saved_at") val savedAt: String,
    @SerialName("updated_at") override val updatedAt: String,
    @SerialName("deleted_at") val deletedAt: String? = null,
) : PulledRow

@Serializable private data class PrayerPush(
    val id: String,
    val text: String,
    val source: String,
    @SerialName("context_note") val contextNote: String?,
    @SerialName("saved_at") val savedAt: String,
)

@Serializable private data class PrayerPull(
    val id: String,
    val text: String,
    @SerialName("context_note") val contextNote: String? = null,
    @SerialName("saved_at") val savedAt: String,
    @SerialName("updated_at") override val updatedAt: String,
    @SerialName("deleted_at") val deletedAt: String? = null,
) : PulledRow

@Serializable private data class ConversationPush(
    val id: String,
    val summary: String?,
    @SerialName("started_at") val startedAt: String,
)

@Serializable private data class ConversationPull(
    val id: String,
    val summary: String? = null,
    @SerialName("started_at") val startedAt: String,
    @SerialName("updated_at") override val updatedAt: String,
    @SerialName("deleted_at") val deletedAt: String? = null,
) : PulledRow

@Serializable private data class MessagePush(
    val id: String,
    @SerialName("conversation_id") val conversationId: String,
    val role: String,
    val content: String,
    @SerialName("sent_at") val sentAt: String,
)

@Serializable private data class MessagePull(
    val id: String,
    @SerialName("conversation_id") val conversationId: String,
    val role: String,
    val content: String,
    @SerialName("sent_at") val sentAt: String,
    @SerialName("updated_at") override val updatedAt: String,
    @SerialName("deleted_at") val deletedAt: String? = null,
) : PulledRow
