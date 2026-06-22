package com.loucesario.seek.ui.chat

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.loucesario.seek.SeekApplication
import com.loucesario.seek.data.SeekPrefs
import com.loucesario.seek.data.local.entity.ChatConversationEntity
import com.loucesario.seek.data.local.entity.ChatMessageEntity
import com.loucesario.seek.data.local.entity.FavoriteVerseEntity
import com.loucesario.seek.data.local.entity.SavedPrayerEntity
import com.loucesario.seek.data.remote.SeekApi
import com.loucesario.seek.data.remote.SeekJson
import com.loucesario.seek.data.remote.dto.ActionStepDto
import com.loucesario.seek.data.remote.dto.ChatHistoryItem
import com.loucesario.seek.data.remote.dto.ChatRequest
import com.loucesario.seek.data.remote.dto.ChatResponse
import com.loucesario.seek.data.remote.dto.VerseDto
import com.loucesario.seek.data.remote.dto.WorshipSongDto
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.UUID

/** One rendered row in the chat transcript. */
sealed interface ChatItem {
    val id: String

    data class UserBubble(override val id: String, val text: String) : ChatItem
    data class Intro(override val id: String, val text: String) : ChatItem
    data class Verses(override val id: String, val verses: List<VerseDto>) : ChatItem
    data class Prayer(override val id: String, val text: String) : ChatItem
    data class Song(override val id: String, val song: WorshipSongDto) : ChatItem
    data class Action(override val id: String, val action: ActionStepDto) : ChatItem
    data class FollowUp(override val id: String, val text: String) : ChatItem
    data class RateLimit(override val id: String, val message: String) : ChatItem
    data class ErrorMsg(override val id: String, val text: String) : ChatItem
}

class ChatViewModel(app: Application) : AndroidViewModel(app) {

    private val db = (app as SeekApplication).database
    private val chatDao = db.chatDao()
    private val favoriteDao = db.favoriteVerseDao()
    private val prayerDao = db.savedPrayerDao()
    private val seekPrefs = SeekPrefs(app)

    private val _items = MutableStateFlow<List<ChatItem>>(emptyList())
    val items: StateFlow<List<ChatItem>> = _items.asStateFlow()

    /** References currently favorited — drives the heart fill on verse cards. */
    val favoritedRefs: StateFlow<Set<String>> = favoriteDao.observeAll()
        .map { list -> list.map { it.reference }.toSet() }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptySet())

    /** Prayer texts currently saved — drives the heart fill on prayer cards. */
    val savedPrayerTexts: StateFlow<Set<String>> = prayerDao.observeAll()
        .map { list -> list.map { it.text }.toSet() }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptySet())

    private val _loading = MutableStateFlow(false)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    private val history = mutableListOf<ChatHistoryItem>()
    private var conversationId: String? = null
    private var lastUserPrompt: String? = null
    var translation: String = "NLT" // set from profile by ChatScreen on open

    private fun newId() = UUID.randomUUID().toString()
    private fun append(item: ChatItem) { _items.value = _items.value + item }

    fun sendMessage(text: String) {
        val message = text.trim().take(500)
        if (message.isEmpty() || _loading.value) return

        lastUserPrompt = message
        append(ChatItem.UserBubble(newId(), message))
        _loading.value = true

        viewModelScope.launch {
            ensureConversation(message)
            persistMessage("user", message)

            val response = callChat(message, history.toList()) ?: return@launch
            history += ChatHistoryItem(role = "user", content = message)
            renderResponse(response)
        }
    }

    /** Re-ask for the last prompt, requesting different scriptures on the same topic. */
    fun regenerate() {
        if (_loading.value) return
        val prompt = lastUserPrompt ?: return
        val current = _items.value
        val lastUserIdx = current.indexOfLast { it is ChatItem.UserBubble }
        if (lastUserIdx < 0) return

        // Strip the trailing assistant rows back to (and keeping) the last user bubble.
        _items.value = current.take(lastUserIdx + 1)
        if (history.isNotEmpty() && history.last().role == "assistant") {
            history.removeAt(history.size - 1)
        }
        _loading.value = true

        viewModelScope.launch {
            val hinted = history.toList() + ChatHistoryItem(
                role = "user",
                content = "Please share different scriptures for my previous message on the same topic.",
            )
            val response = callChat(prompt, hinted) ?: return@launch
            renderResponse(response)
        }
    }

    /** Performs the API call + error handling. Returns null (after appending an error/rate-limit row) on failure. */
    private suspend fun callChat(message: String, hist: List<ChatHistoryItem>): ChatResponse? {
        val response: ChatResponse = try {
            SeekApi.sendChat(
                ChatRequest(message = message, conversationHistory = hist, translation = translation)
            )
        } catch (t: Throwable) {
            _loading.value = false
            append(ChatItem.ErrorMsg(newId(), "Something went wrong finding scripture for you. Please try again."))
            return null
        }

        _loading.value = false

        if (response.error != null || (response.verses.isEmpty() && response.message.isNullOrBlank())) {
            if (response.error == "daily_limit_reached" || response.error?.contains("limit") == true) {
                append(ChatItem.RateLimit(newId(), response.message ?: "You've reached today's limit. Resets at midnight, your local time."))
            } else {
                append(ChatItem.ErrorMsg(newId(), response.message ?: "Something went wrong. Please try again."))
            }
            return null
        }
        return response
    }

    /** Appends the parsed response rows + updates history + persists. */
    private suspend fun renderResponse(response: ChatResponse) {
        response.message?.takeIf { it.isNotBlank() }?.let { append(ChatItem.Intro(newId(), it)) }
        if (response.verses.isNotEmpty()) {
            append(ChatItem.Verses(newId(), response.verses))
            seekPrefs.addVersesExplored(response.verses.size)
        }
        response.prayer?.takeIf { it.isNotBlank() }?.let { append(ChatItem.Prayer(newId(), it)) }
        response.worshipSong?.let { append(ChatItem.Song(newId(), it)) }
        response.action?.let { append(ChatItem.Action(newId(), it)) }
        response.followUp?.takeIf { it.isNotBlank() }?.let { append(ChatItem.FollowUp(newId(), it)) }

        history += ChatHistoryItem(role = "assistant", content = response.message ?: "")
        persistMessage("assistant", SeekJson.encodeToString(ChatResponse.serializer(), response))
    }

    /** True when there's a completed response to regenerate and we're idle. */
    fun canRegenerate(): Boolean {
        if (_loading.value || lastUserPrompt == null) return false
        val last = _items.value.lastOrNull() ?: return false
        return last !is ChatItem.UserBubble && last !is ChatItem.ErrorMsg && last !is ChatItem.RateLimit
    }

    /** Heart/unheart a verse — mirrors the iOS favorite toggle (keyed on reference). */
    fun toggleFavorite(verse: VerseDto) {
        viewModelScope.launch {
            if (favoritedRefs.value.contains(verse.reference)) {
                favoriteDao.deleteByReference(verse.reference)
            } else {
                favoriteDao.insert(
                    FavoriteVerseEntity(
                        id = newId(),
                        reference = verse.reference,
                        text = verse.text,
                        savedAt = System.currentTimeMillis(),
                        source = "chat",
                    )
                )
            }
        }
    }

    /** Save/unsave a prayer — keyed on its text, with the prompt that produced it. */
    fun togglePrayer(text: String) {
        viewModelScope.launch {
            if (savedPrayerTexts.value.contains(text)) {
                prayerDao.deleteByText(text)
            } else {
                prayerDao.insert(
                    SavedPrayerEntity(
                        id = newId(),
                        text = text,
                        contextNote = lastUserPrompt,
                        savedAt = System.currentTimeMillis(),
                    )
                )
            }
        }
    }

    fun reset() {
        _items.value = emptyList()
        history.clear()
        conversationId = null
    }

    private suspend fun ensureConversation(firstMessage: String) {
        if (conversationId != null) return
        val id = newId()
        conversationId = id
        chatDao.upsertConversation(
            ChatConversationEntity(id = id, startedAt = System.currentTimeMillis(), summary = firstMessage.take(80))
        )
    }

    private suspend fun persistMessage(role: String, content: String) {
        val convo = conversationId ?: return
        chatDao.insertMessage(
            ChatMessageEntity(
                id = newId(),
                conversationId = convo,
                role = role,
                content = content,
                timestamp = System.currentTimeMillis(),
            )
        )
    }
}
