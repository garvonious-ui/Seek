package com.loucesario.seek.data.remote

import com.loucesario.seek.data.remote.dto.ChatRequest
import com.loucesario.seek.data.remote.dto.ChatResponse
import com.loucesario.seek.data.remote.dto.DailyVerseDto
import io.github.jan.supabase.functions.functions
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.contentType
import kotlinx.serialization.json.Json

/** Lenient JSON — Edge Functions may add fields; never crash on unknowns. */
val SeekJson = Json {
    ignoreUnknownKeys = true
    isLenient = true
    encodeDefaults = true
}

/**
 * Thin wrapper over the shared Edge Functions. Both `chat` and `daily-verse`
 * are deployed --no-verify-jwt and validate auth in-function, so the anon-key
 * client works for guests; the user's session token (when present) is attached
 * automatically by supabase-kt's Functions plugin.
 *
 * NOTE: the exact `functions.invoke` builder signature in supabase-kt 3.x should
 * be confirmed on first Gradle sync (IDE autocomplete). The request is encoded
 * to a JSON string and the response decoded manually so we don't depend on
 * ktor reified-type content negotiation.
 */
object SeekApi {

    suspend fun sendChat(request: ChatRequest): ChatResponse {
        val payload = SeekJson.encodeToString(ChatRequest.serializer(), request)
        val response = SupabaseModule.client.functions.invoke("chat") {
            setBody(payload)
            contentType(ContentType.Application.Json)
        }
        return SeekJson.decodeFromString(ChatResponse.serializer(), response.bodyAsText())
    }

    suspend fun dailyVerse(): DailyVerseDto {
        val response = SupabaseModule.client.functions.invoke("daily-verse")
        return SeekJson.decodeFromString(DailyVerseDto.serializer(), response.bodyAsText())
    }
}
