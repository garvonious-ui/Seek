package com.loucesario.seek.data.remote

import com.loucesario.seek.data.remote.dto.ChatRequest
import com.loucesario.seek.data.remote.dto.ChatResponse
import com.loucesario.seek.data.remote.dto.DailyVerseDto
import com.loucesario.seek.data.remote.dto.PreflightRequest
import com.loucesario.seek.data.remote.dto.PreflightResult
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.exceptions.RestException
import io.github.jan.supabase.functions.functions
import io.github.jan.supabase.postgrest.from
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

    /**
     * Asks `auth-preflight` what's true about this email before promising a
     * reset. resetPasswordForEmail() returns success for ANY address, so it
     * can't tell Google/Apple-only accounts (no password) or unknown emails
     * apart from real ones; this function sends the reset itself when it's real.
     *
     * supabase-kt throws a [RestException] on non-2xx with the raw body in
     * `error` — rate_limited / send_failed / … still carry {status, message}.
     * Network failures propagate to the caller.
     */
    suspend fun authPreflight(email: String): PreflightResult {
        val payload = SeekJson.encodeToString(PreflightRequest.serializer(), PreflightRequest(email))
        return try {
            val response = SupabaseModule.client.functions.invoke("auth-preflight") {
                setBody(payload)
                contentType(ContentType.Application.Json)
            }
            SeekJson.decodeFromString(PreflightResult.serializer(), response.bodyAsText())
        } catch (e: RestException) {
            runCatching { SeekJson.decodeFromString(PreflightResult.serializer(), e.error) }
                .getOrElse { PreflightResult(status = "server_error") }
        }
    }

    suspend fun dailyVerse(): DailyVerseDto {
        val response = SupabaseModule.client.functions.invoke("daily-verse")
        return SeekJson.decodeFromString(DailyVerseDto.serializer(), response.bodyAsText())
    }

    /**
     * Mirrors the user's preferred translation (NLT/KJV) to Supabase
     * `profiles.preferred_translation` so the daily-verse Edge Function and any
     * other device pick it up. No-op for guests (no session). Best-effort —
     * callers wrap in runCatching; the local preference is the source of truth
     * for chat requests.
     */
    suspend fun updatePreferredTranslation(translation: String) {
        val uid = SupabaseModule.client.auth.currentSessionOrNull()?.user?.id ?: return
        SupabaseModule.client.from("profiles").update(
            { set("preferred_translation", translation) },
        ) {
            filter { eq("id", uid) }
        }
    }

    /**
     * Permanently deletes the signed-in user's account + all server-side data
     * (the `delete-account` Edge Function deletes the auth user, cascading to
     * profiles / notification_settings / usage_logs). The session token is
     * attached automatically by the Functions plugin and must still be valid
     * when this is called (i.e. before sign-out).
     */
    suspend fun deleteAccount() {
        val response = SupabaseModule.client.functions.invoke("delete-account") {
            contentType(ContentType.Application.Json)
        }
        if (response.status.value !in 200..299) {
            throw IllegalStateException("Account deletion failed (${response.status.value})")
        }
    }
}
