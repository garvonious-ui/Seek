package com.loucesario.seek.data.remote.dto

import kotlinx.serialization.Serializable

/** Request for the `auth-preflight` Edge Function (shared with iOS). */
@Serializable
data class PreflightRequest(val email: String)

/**
 * Response from `auth-preflight`. Non-2xx responses carry the same shape.
 * status: sent | oauth_only | no_account | rate_limited | invalid_email | send_failed | server_error
 * [message] is user-presentable — render it rather than writing new copy.
 */
@Serializable
data class PreflightResult(
    val status: String,
    val provider: String? = null,
    val providers: List<String> = emptyList(),
    val message: String? = null,
)
