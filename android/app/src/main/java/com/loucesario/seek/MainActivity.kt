package com.loucesario.seek

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.loucesario.seek.data.remote.SupabaseModule
import com.loucesario.seek.ui.SeekApp
import com.loucesario.seek.ui.theme.SeekTheme
import io.github.jan.supabase.auth.handleDeeplinks

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Consume an OAuth redirect (seek://auth-callback) if we were cold-launched by one.
        SupabaseModule.client.handleDeeplinks(intent)
        enableEdgeToEdge()
        setContent {
            SeekTheme {
                SeekApp()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Google/Apple OAuth redirect lands here when the app is already running
        // (launchMode=singleTask routes it to this instance). supabase-kt parses
        // the session from the URL; the sessionStatus listener flips auth state.
        SupabaseModule.client.handleDeeplinks(intent)
    }
}
