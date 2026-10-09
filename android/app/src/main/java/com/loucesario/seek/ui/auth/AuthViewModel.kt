package com.loucesario.seek.ui.auth

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.loucesario.seek.SeekApplication
import com.loucesario.seek.data.SeekSession
import com.loucesario.seek.data.SessionRepository
import com.loucesario.seek.data.remote.SeekApi
import com.loucesario.seek.data.remote.SupabaseModule
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.Apple
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.status.SessionSource
import io.github.jan.supabase.auth.status.SessionStatus
import io.github.jan.supabase.auth.user.UserSession
import io.github.jan.supabase.exceptions.HttpRequestException
import io.github.jan.supabase.exceptions.RestException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class AuthUiState(
    val loading: Boolean = false,
    val error: String? = null,
    val resetOutcome: PasswordResetOutcome? = null,
)

/** What Forgot Password learned from `auth-preflight` — each shown as a dialog. */
sealed interface PasswordResetOutcome {
    val message: String

    data class Sent(override val message: String) : PasswordResetOutcome
    data class OAuthOnly(val provider: String, override val message: String) : PasswordResetOutcome
    data class NoAccount(override val message: String) : PasswordResetOutcome
}

/** Dialogs driven by the seek://password-reset link from the reset email. */
enum class RecoveryDialog { SET_PASSWORD, PASSWORD_UPDATED, LINK_EXPIRED }

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

    // Separate from [ui] — every auth action resets AuthUiState, and these must
    // survive it (they're shown app-wide, signed in or not).
    private val _recoveryDialog = MutableStateFlow<RecoveryDialog?>(null)
    val recoveryDialog: StateFlow<RecoveryDialog?> = _recoveryDialog.asStateFlow()

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

    /**
     * Forgot Password. Goes through `auth-preflight` instead of
     * resetPasswordForEmail(), which claims success for ANY email — including
     * Google/Apple-only accounts that have no password, and nonexistent ones.
     * Renders the server's message rather than duplicating copy here.
     */
    fun resetPassword(email: String) {
        if (email.isBlank()) {
            _ui.value = AuthUiState(error = "Enter your email address first.")
            return
        }
        viewModelScope.launch {
            _ui.value = AuthUiState(loading = true)
            _ui.value = try {
                val result = SeekApi.authPreflight(email.trim())
                when (result.status) {
                    "sent" -> AuthUiState(
                        resetOutcome = PasswordResetOutcome.Sent(
                            result.message ?: "Check your email for a password reset link."
                        )
                    )
                    "oauth_only" -> AuthUiState(
                        resetOutcome = PasswordResetOutcome.OAuthOnly(
                            provider = result.provider.orEmpty().lowercase(),
                            message = result.message ?: "This account doesn't use a password.",
                        )
                    )
                    "no_account" -> AuthUiState(
                        resetOutcome = PasswordResetOutcome.NoAccount(
                            result.message ?: "We couldn't find an account with that email."
                        )
                    )
                    "invalid_email" -> AuthUiState(error = "Enter a valid email address.")
                    else -> AuthUiState(error = result.message ?: GENERIC_ERROR)
                }
            } catch (e: HttpRequestException) {
                AuthUiState(error = "Couldn't reach Seek. Check your connection and try again.")
            } catch (t: Throwable) {
                AuthUiState(error = GENERIC_ERROR)
            }
        }
    }

    fun clearResetOutcome() {
        _ui.value = _ui.value.copy(resetOutcome = null)
    }

    /**
     * Handles seek://password-reset from the reset email. auth-preflight sends
     * it server-side with supabase-js's default implicit flow, so the tokens
     * arrive in the URL fragment (errors may be in the fragment or the query).
     *
     * The user is fetched with the link's access token BEFORE the session is
     * imported, so a dead link never half-signs anyone in (or replaces an
     * existing session). Anyone resetting a password is a returning user, so
     * success takes the same path as email sign-in, then asks for the new
     * password.
     */
    fun handlePasswordRecovery(uri: Uri) {
        viewModelScope.launch {
            try {
                val params = recoveryLinkParams(uri)
                check(params["error"] == null && params["error_code"] == null) {
                    "Reset link error: ${params["error_code"] ?: params["error"]}"
                }
                val accessToken = checkNotNull(params["access_token"]) { "No access token in reset link" }
                val refreshToken = checkNotNull(params["refresh_token"]) { "No refresh token in reset link" }

                val auth = SupabaseModule.client.auth
                // A cold-start import must not race the stored-session load.
                auth.awaitInitialization()
                val user = auth.retrieveUser(accessToken)
                auth.importSession(
                    UserSession(
                        accessToken = accessToken,
                        refreshToken = refreshToken,
                        expiresIn = params["expires_in"]?.toLongOrNull() ?: 3600,
                        tokenType = params["token_type"] ?: "bearer",
                        user = user,
                        type = params["type"] ?: "recovery",
                    ),
                    source = SessionSource.External,
                )
                sessionRepo.onAuthSuccess()
                _recoveryDialog.value = RecoveryDialog.SET_PASSWORD
            } catch (t: Throwable) {
                _recoveryDialog.value = RecoveryDialog.LINK_EXPIRED
            }
        }
    }

    /** Sets the new password on the recovery session. [onResult] gets null on success, else an error. */
    fun updatePassword(newPassword: String, onResult: (String?) -> Unit) {
        viewModelScope.launch {
            try {
                SupabaseModule.client.auth.updateUser { password = newPassword }
                _recoveryDialog.value = RecoveryDialog.PASSWORD_UPDATED
                onResult(null)
            } catch (t: Throwable) {
                // RestException.description is GoTrue's own message (e.g. "New password
                // should be different from the old password."); `message` adds the URL + headers.
                val reason = (t as? RestException)?.description
                onResult(
                    if (reason != null) "Couldn't update your password: $reason"
                    else "Couldn't update your password. Please try again."
                )
            }
        }
    }

    /** "Not now" / OK — the user stays signed in either way. */
    fun dismissRecoveryDialog() {
        _recoveryDialog.value = null
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

    /**
     * Permanently deletes the account: server-side delete (Edge Function) →
     * wipe local Room data → clear the session and reset to a fresh install.
     * On success the auth state flips to UNAUTHENTICATED, routing to onboarding.
     */
    fun deleteAccount(onResult: (Boolean) -> Unit = {}) {
        viewModelScope.launch {
            _ui.value = AuthUiState(loading = true)
            try {
                SeekApi.deleteAccount() // token still valid here
                withContext(Dispatchers.IO) {
                    (getApplication() as SeekApplication).database.clearAllTables()
                }
                sessionRepo.deleteAccountReset()
                _ui.value = AuthUiState()
                onResult(true)
            } catch (t: Throwable) {
                _ui.value = AuthUiState(error = t.message ?: "Couldn't delete your account. Please try again.")
                onResult(false)
            }
        }
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

    private companion object {
        const val GENERIC_ERROR = "Something went wrong. Please try again."
    }
}

/**
 * Query + fragment params of a recovery link, URL-decoded (fragment wins).
 * seek://password-reset#access_token=…&refresh_token=…&type=recovery, or
 * …#error=access_denied&error_code=otp_expired&… for a used/expired link.
 */
private fun recoveryLinkParams(uri: Uri): Map<String, String> =
    listOfNotNull(uri.encodedQuery, uri.encodedFragment)
        .flatMap { it.split('&') }
        .mapNotNull { part ->
            val eq = part.indexOf('=')
            if (eq <= 0) null else Uri.decode(part.substring(0, eq)) to Uri.decode(part.substring(eq + 1))
        }
        .toMap()
