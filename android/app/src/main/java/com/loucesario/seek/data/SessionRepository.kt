package com.loucesario.seek.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import com.loucesario.seek.data.remote.SupabaseModule
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.status.SessionStatus
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map

private val Context.authDataStore by preferencesDataStore(name = "auth_flags")

/** Mirrors the iOS auth state machine + the guest/onboarding flags. */
enum class AuthState { UNAUTHENTICATED, AUTHENTICATED }

data class SeekSession(
    val authState: AuthState = AuthState.UNAUTHENTICATED,
    val hasCompletedOnboarding: Boolean = false,
    val hasOptedForGuest: Boolean = false,
) {
    /** Guest = browsing without an account (see iOS AuthManager.isGuest). */
    val isGuest: Boolean get() = authState == AuthState.UNAUTHENTICATED && hasOptedForGuest
}

/**
 * Owns auth-derived state.
 *
 * CRITICAL (cost iOS Builds 8 & 9 — see docs/android-plan.md + memory):
 *  - Trust the persisted session, NOT listener events. We cross-check
 *    [io.github.jan.supabase.auth.Auth.currentSessionOrNull] before treating any
 *    "signed out" signal as real.
 *  - Set ALL derived flags (hasOptedForGuest, hasCompletedOnboarding) directly
 *    and atomically in each auth-success path. NEVER let a session-status
 *    listener clear them as a side effect.
 */
class SessionRepository(private val appContext: Context) {

    private val hasOnboardedKey = booleanPreferencesKey("has_completed_onboarding")
    private val hasGuestKey = booleanPreferencesKey("has_opted_for_guest")

    private val _session = MutableStateFlow(SeekSession())
    val session: StateFlow<SeekSession> = _session.asStateFlow()

    val flags: Flow<Pair<Boolean, Boolean>> = appContext.authDataStore.data.map { prefs ->
        (prefs[hasOnboardedKey] ?: false) to (prefs[hasGuestKey] ?: false)
    }

    /**
     * Resolve initial state from the keychain-equivalent (Supabase persisted
     * session), trusting the stored session over any event.
     */
    suspend fun bootstrap(hasOnboarded: Boolean, hasOptedForGuest: Boolean) {
        val hasSession = SupabaseModule.client.auth.currentSessionOrNull() != null
        _session.value = SeekSession(
            authState = if (hasSession) AuthState.AUTHENTICATED else AuthState.UNAUTHENTICATED,
            hasCompletedOnboarding = hasOnboarded,
            hasOptedForGuest = hasOptedForGuest,
        )
    }

    /** Apply a real session-status change, gating "signed out" on the actual session. */
    fun onStatusChange(status: SessionStatus) {
        when (status) {
            is SessionStatus.Authenticated -> markAuthenticated()
            is SessionStatus.NotAuthenticated -> {
                // Defensive: only honor sign-out if the session is truly gone.
                if (SupabaseModule.client.auth.currentSessionOrNull() == null) {
                    _session.value = _session.value.copy(authState = AuthState.UNAUTHENTICATED)
                }
            }
            else -> Unit // Initializing / RefreshFailure — don't touch auth state
        }
    }

    /** Atomic success transition — every sign-in path calls this. */
    private fun markAuthenticated() {
        _session.value = _session.value.copy(
            authState = AuthState.AUTHENTICATED,
            hasOptedForGuest = false, // cleared HERE, not via listener
            hasCompletedOnboarding = true,
        )
    }

    suspend fun continueAsGuest() {
        // If a stale session lingers, sign out first (iOS defensive continueAsGuest).
        if (SupabaseModule.client.auth.currentSessionOrNull() != null) {
            SupabaseModule.client.auth.signOut()
        }
        appContext.authDataStore.edit { it[hasGuestKey] = true }
        _session.value = _session.value.copy(
            authState = AuthState.UNAUTHENTICATED,
            hasOptedForGuest = true,
        )
    }

    suspend fun setOnboardingComplete(complete: Boolean) {
        appContext.authDataStore.edit { it[hasOnboardedKey] = complete }
        _session.value = _session.value.copy(hasCompletedOnboarding = complete)
    }

    /** Explicit user-initiated sign-out owns its own reset (not the listener). */
    suspend fun signOut() {
        SupabaseModule.client.auth.signOut()
        appContext.authDataStore.edit {
            it[hasGuestKey] = false
            it[hasOnboardedKey] = false
        }
        _session.value = SeekSession()
    }
}
