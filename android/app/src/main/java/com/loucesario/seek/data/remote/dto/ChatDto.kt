package com.loucesario.seek.data.remote.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Request/response DTOs for the `chat` and `daily-verse` Edge Functions.
 * Shapes mirror docs/api-routes.md exactly — both functions are shared with iOS.
 */

@Serializable
data class ChatRequest(
    val message: String,
    val conversationHistory: List<ChatHistoryItem> = emptyList(),
    val translation: String = "NLT",
)

@Serializable
data class ChatHistoryItem(
    val role: String, // "user" | "assistant"
    val content: String,
)

@Serializable
data class ChatResponse(
    val message: String? = null,
    val verses: List<VerseDto> = emptyList(),
    val prayer: String? = null,
    val worshipSong: WorshipSongDto? = null,
    val followUp: String? = null,
    val remainingChats: Int? = null,
    // 429 payload
    val error: String? = null,
    val resetsAt: String? = null,
)

@Serializable
data class VerseDto(
    val reference: String,
    val text: String,
    val context: String? = null,
)

@Serializable
data class WorshipSongDto(
    val title: String,
    val artist: String,
    val context: String? = null,
)

@Serializable
data class DailyVerseDto(
    val reference: String,
    val text: String,
    val theme: String? = null,
)
