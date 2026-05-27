package com.loucesario.seek.ui.auth

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.loucesario.seek.SeekApplication
import com.loucesario.seek.data.SeekSession
import com.loucesario.seek.data.SessionRepository
import com.loucesario.seek.data.remote.SupabaseModule
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.Apple
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.status.SessionStatus
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class AuthUiState(
    val loading: Boolean = false,
    val error: String? = null,
    val resetEmailSent: Boolean = false,
)

/**
 * Drives all auth. Per the iOS gotcha (cost Builds 8 & 9): every success path
 * calls [SessionRepository.onAuthSuccess] directly and atomically — we do NOT
 * rely on the session-status listener to flip app state. The listener only
 * restores state on cold start and defensively handles real sign-outs.
 */
class AuthViewModel(app: Application) : AndroidViewModel(app) {

    private val sessionRepo: SessionRepository =
        (app as SeekApplication).sessionRepository

    val session: StateFlow<SeekSession> = sessionRepo.session

    private val _ui = MutableStateFlow(AuthUiState())
    val ui: StateFlow<AuthUiState> = _ui.asStateFlow()

    init {
        // Cold-start restoration: load persisted flags + trust the keychain.
        viewModelScope.launch {
            sessionRepo.flags.collect { (onboarded, guest) ->
                sessionRepo.bootstrap(onboarded, guest)
            }
        }
        // Defensive listener — never flips guest/onboarding flags itself.
        viewModelScope.launch {
            SupabaseModule.client.auth.sessionStatus.collect { status: SessionStatus ->
                sessionRepo.onStatusChange(status)
            }
        }
    }

    fun signInWithEmail(email: String, password: String) = run("Couldn't sign in.") {
        SupabaseModule.client.auth.signInWith(Email) {
            this.email = email.trim()
            this.password = password
        }
        sessionRepo.onAuthSuccess()
    }

    fun signUpWithEmail(email: String, password: String) = run("Couldn't create your account.") {
        SupabaseModule.client.auth.signUpWith(Email) {
            this.email = email.trim()
            this.password = password
        }
        // If email confirmation is off, a session exists now → authenticate.
        if (SupabaseModule.client.auth.currentSessionOrNull() != null) {
            sessionRepo.onAuthSuccess()
        } else {
            _ui.value = AuthUiState(error = "Check your email to confirm your account.")
        }
    }

    fun resetPassword(email: String) = run("Couldn't send reset email.") {
        SupabaseModule.client.auth.resetPasswordForEmail(email.trim())
        _ui.value = AuthUiState(resetEmailSent = true)
    }

    /** Browser OAuth — works once the Google provider is configured in Supabase. */
    fun signInWithGoogle() = run("Google sign-in isn't available yet.") {
        SupabaseModule.client.auth.signInWith(Google)
        // Completion arrives via the session-status listener (deep-link callback).
    }

    /** Browser OAuth — needs the Apple OAuth Services ID configured in Supabase. */
    fun signInWithApple() = run("Apple sign-in isn't available yet.") {
        SupabaseModule.client.auth.signInWith(Apple)
    }

    fun continueAsGuest() = run("Couldn't continue.") {
        sessionRepo.continueAsGuest()
    }

    fun exitGuest() = run("Couldn't continue.") {
        sessionRepo.exitGuest()
    }

    fun completeOnboarding() {
        viewModelScope.launch { sessionRepo.setOnboardingComplete(true) }
    }

    fun signOut() = run("Couldn't sign out.") {
        sessionRepo.signOut()
    }

    fun clearError() {
        _ui.value = _ui.value.copy(error = null)
    }

    private inline fun run(errorMessage: String, crossinline block: suspend () -> Unit) {
        viewModelScope.launch {
            _ui.value = AuthUiState(loading = true)
            try {
                block()
                if (_ui.value.loading) _ui.value = AuthUiState()
            } catch (t: Throwable) {
                _ui.value = AuthUiState(error = t.message ?: errorMessage)
            }
        }
    }
}
