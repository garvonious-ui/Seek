package com.loucesario.seek.ui.chat

/**
 * In-memory hand-off for a chat message started from elsewhere (the Home quick
 * prompts / Home free-text input). Set [pending] before switching to the Chat
 * tab; ChatScreen consumes it once on appear and auto-sends. Mirrors the
 * CardDraft pattern — avoids threading nav-path args for free-text content.
 */
object ChatDraft {
    var pending: String? = null

    /** Returns the pending message and clears it, so it's only consumed once. */
    fun consume(): String? {
        val msg = pending
        pending = null
        return msg
    }
}
