package com.loucesario.seek.ui.library

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

/** Phase 3 placeholder — Cards / Favorites / History tabs land here. */
@Composable
fun LibraryScreen() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(SeekColors.Background)
            .padding(24.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "Your saved cards, verses, and conversations\n\n(Library — Phase 3)",
            color = SeekColors.TextSecondary,
            textAlign = TextAlign.Center,
        )
    }
}
