package com.loucesario.seek

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import com.loucesario.seek.data.remote.SupabaseModule
import com.loucesario.seek.ui.SeekApp
import com.loucesario.seek.ui.auth.AuthViewModel
import com.loucesario.seek.ui.theme.SeekTheme
import io.github.jan.supabase.auth.handleDeeplinks

class MainActivity : ComponentActivity() {
    // Same instance SeekApp gets from viewModel() — both use this activity's store.
    private val authVm: AuthViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Consume an OAuth redirect (seek://auth-callback) if we were cold-launched by one.
        SupabaseModule.client.handleDeeplinks(intent)
        // Skip on recreation (rotation etc.) — the launch intent was already handled.
        if (savedInstanceState == null) handlePasswordResetLink(intent)
        enableEdgeToEdge()
        setContent {
            SeekTheme {
                SeekApp()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        // Cloud sync: back up / catch up whenever the app comes to the foreground.
        // No-op while signed out.
        (application as SeekApplication).sync.requestSync()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Google/Apple OAuth redirect lands here when the app is already running
        // (launchMode=singleTask routes it to this instance). supabase-kt parses
        // the session from the URL; the sessionStatus listener flips auth state.
        SupabaseModule.client.handleDeeplinks(intent)
        handlePasswordResetLink(intent)
    }

    /**
     * seek://password-reset from the reset email. handleDeeplinks ignores it
     * (it only matches the configured auth-callback host), so AuthViewModel
     * imports the recovery session itself.
     */
    private fun handlePasswordResetLink(intent: Intent) {
        val uri = intent.data ?: return
        if (uri.scheme != "seek" || uri.host != "password-reset") return
        // Reopened from Recents: the original (now spent) link is redelivered.
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return
        authVm.handlePasswordRecovery(uri)
    }
}
