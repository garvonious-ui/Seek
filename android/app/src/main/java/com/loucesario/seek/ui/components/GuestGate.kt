package com.loucesario.seek.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.loucesario.seek.ui.theme.SeekColors

/**
 * Shown on account-gated tabs (Chat, Library) when browsing as a guest.
 * Mirrors the iOS GuestGateView. Sign-in itself happens by navigating to the
 * Profile tab → Sign In (guests reach the onboarding gate via sign-out-of-guest).
 */
@Composable
fun GuestGate(title: String, message: String) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(SeekColors.Background)
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(
            Icons.Outlined.Lock,
            contentDescription = null,
            tint = SeekColors.MidSage,
            modifier = Modifier.size(44.dp),
        )
        Text(
            title,
            fontSize = 20.sp,
            fontWeight = FontWeight.SemiBold,
            color = SeekColors.TextPrimary,
            modifier = Modifier.padding(top = 16.dp),
        )
        Text(
            message,
            fontSize = 15.sp,
            color = SeekColors.TextSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 8.dp),
        )
        Text(
            "Open the profile tab to sign in.",
            fontSize = 13.sp,
            color = SeekColors.MidSage,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 16.dp),
        )
    }
}
