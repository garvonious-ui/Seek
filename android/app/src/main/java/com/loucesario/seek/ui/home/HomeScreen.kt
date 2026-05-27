package com.loucesario.seek.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.loucesario.seek.ui.theme.ScriptureTextStyle
import com.loucesario.seek.ui.theme.SeekColors

/**
 * Phase 0 placeholder. Renders the wordmark line + a static daily-verse card so
 * the theme, color tokens, and scripture serif are visible on first run.
 * Phase 1 wires SeekApi.dailyVerse(), the streak capsule, and quick prompts.
 */
@Composable
fun HomeScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(SeekColors.Background)
            .padding(horizontal = 20.dp, vertical = 16.dp),
    ) {
        Text(
            text = "Seek",
            fontSize = 32.sp,
            fontWeight = FontWeight.SemiBold,
            color = SeekColors.TextPrimary,
        )
        Spacer(Modifier.height(24.dp))

        Text(
            text = "TODAY'S VERSE",
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
            color = SeekColors.TextSecondary,
        )
        Spacer(Modifier.height(8.dp))

        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = CardDefaults.cardColors(containerColor = SeekColors.Surface),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(
                    text = "God is our refuge and strength, always ready to help in times of trouble.",
                    style = ScriptureTextStyle,
                    color = SeekColors.TextPrimary,
                )
                Text(
                    text = "Psalm 46:1",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = SeekColors.Sage,
                )
            }
        }
    }
}
