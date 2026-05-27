package com.loucesario.seek.ui.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.loucesario.seek.ui.components.GuestGate
import com.loucesario.seek.ui.theme.SeekColors

/** Phase 2 will build the scripture chat here. Guests see a sign-in gate. */
@Composable
fun ChatScreen(isGuest: Boolean) {
    if (isGuest) {
        GuestGate(title = "Sign in to chat", message = "Create a free account to talk through what's on your heart.")
        return
    }
    Box(
        modifier = Modifier.fillMaxSize().background(SeekColors.Background).padding(24.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            "What's on your heart?\n\n(Scripture chat — Phase 2)",
            color = SeekColors.TextSecondary,
            textAlign = TextAlign.Center,
        )
    }
}
