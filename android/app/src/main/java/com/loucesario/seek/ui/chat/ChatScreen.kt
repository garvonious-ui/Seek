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
import com.loucesario.seek.ui.theme.SeekColors

/** Phase 2 placeholder — the scripture chat core loop lands here. */
@Composable
fun ChatScreen() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(SeekColors.Background)
            .padding(24.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "What's on your heart?\n\n(Scripture chat — Phase 2)",
            color = SeekColors.TextSecondary,
            textAlign = TextAlign.Center,
        )
    }
}
