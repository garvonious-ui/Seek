package com.loucesario.seek.ui.chat

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.loucesario.seek.SeekApplication
import com.loucesario.seek.data.local.entity.ChatConversationEntity
import com.loucesario.seek.data.local.entity.ChatMessageEntity
import com.loucesario.seek.data.remote.SeekApi
import com.loucesario.seek.data.remote.SeekJson
import com.loucesario.seek.data.remote.dto.ChatHistoryItem
import com.loucesario.seek.data.remote.dto.ChatRequest
import com.loucesario.seek.data.remote.dto.ChatResponse
import com.loucesario.seek.data.remote.dto.VerseDto
import com.loucesario.seek.data.remote.dto.WorshipSongDto
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
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
    data class FollowUp(override val id: String, val text: String) : ChatItem
    data class RateLimit(override val id: String, val message: String) : ChatItem
    data class ErrorMsg(override val id: String, val text: String) : ChatItem
}

class ChatViewModel(app: Application) : AndroidViewModel(app) {

    private val chatDao = (app as SeekApplication).database.chatDao()

    private val _items = MutableStateFlow<List<ChatItem>>(emptyList())
    val items: StateFlow<List<ChatItem>> = _items.asStateFlow()

    private val _loading = MutableStateFlow(false)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    private val history = mutableListOf<ChatHistoryItem>()
    private var conversationId: String? = null
    private val translation = "NLT" // wired to profile in a later phase

    private fun newId() = UUID.randomUUID().toString()
    private fun append(item: ChatItem) { _items.value = _items.value + item }

    fun sendMessage(text: String) {
        val message = text.trim().take(500)
        if (message.isEmpty() || _loading.value) return

        append(ChatItem.UserBubble(newId(), message))
        _loading.value = true

        viewModelScope.launch {
            ensureConversation(message)
            persistMessage("user", message)

            val response: ChatResponse = try {
                SeekApi.sendChat(
                    ChatRequest(message = message, conversationHistory = history.toList(), translation = translation)
                )
            } catch (t: Throwable) {
                _loading.value = false
                append(ChatItem.ErrorMsg(newId(), "Something went wrong finding scripture for you. Please try again."))
                return@launch
            }

            _loading.value = false
            history += ChatHistoryItem(role = "user", content = message)

            if (response.error != null || response.verses.isEmpty() && response.message.isNullOrBlank()) {
                if (response.error == "daily_limit_reached" || response.error?.contains("limit") == true) {
                    append(ChatItem.RateLimit(newId(), response.message ?: "You've reached today's limit. Resets at midnight, your local time."))
                } else {
                    append(ChatItem.ErrorMsg(newId(), response.message ?: "Something went wrong. Please try again."))
                }
                return@launch
            }

            response.message?.takeIf { it.isNotBlank() }?.let { append(ChatItem.Intro(newId(), it)) }
            if (response.verses.isNotEmpty()) append(ChatItem.Verses(newId(), response.verses))
            response.prayer?.takeIf { it.isNotBlank() }?.let { append(ChatItem.Prayer(newId(), it)) }
            response.worshipSong?.let { append(ChatItem.Song(newId(), it)) }
            response.followUp?.takeIf { it.isNotBlank() }?.let { append(ChatItem.FollowUp(newId(), it)) }

            history += ChatHistoryItem(role = "assistant", content = response.message ?: "")
            persistMessage("assistant", SeekJson.encodeToString(ChatResponse.serializer(), response))
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
