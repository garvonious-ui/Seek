package com.loucesario.seek.ui.weekly

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.ProvideTextStyle
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.loucesario.seek.data.WeeklySummary
import com.loucesario.seek.ui.theme.ScriptureFontFamily
import com.loucesario.seek.ui.theme.SeekColors

/** "Your week is ready" card on Home — Sunday noon through Tuesday. Port of the iOS WeeklyRecapTile. */
@Composable
fun WeeklyRecapTile(
    summary: WeeklySummary,
    onOpen: () -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = SeekColors.Surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        ProvideTextStyle(RecapTextStyle) {
            Row(Modifier.padding(16.dp), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                MiniCard(summary)

                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Row {
                        Text(
                            "YOUR WEEK IS READY",
                            fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.5.sp,
                            color = RecapDarkGold, modifier = Modifier.weight(1f),
                        )
                        Box(
                            modifier = Modifier
                                .offset(x = 6.dp, y = (-6).dp)
                                .size(28.dp)
                                .clip(CircleShape)
                                .clickable(role = Role.Button, onClick = onDismiss)
                                .semantics { contentDescription = "Dismiss weekly recap" },
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(
                                Icons.Filled.Close, contentDescription = null,
                                tint = SeekColors.TextTertiary, modifier = Modifier.size(16.dp),
                            )
                        }
                    }

                    Text(headline(summary), fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary)
                    Text(summary.dateRange, fontSize = 13.sp, color = SeekColors.TextSecondary)

                    Surface(
                        onClick = onOpen,
                        modifier = Modifier.padding(top = 4.dp),
                        shape = CircleShape,
                        color = SeekColors.Sage,
                    ) {
                        Row(
                            modifier = Modifier.heightIn(min = 36.dp).padding(horizontal = 16.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(
                                Icons.Outlined.Share, contentDescription = null,
                                tint = SeekColors.Surface, modifier = Modifier.size(16.dp),
                            )
                            Spacer(Modifier.size(6.dp))
                            Text("View & share", fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Surface)
                        }
                    }
                }
            }
        }
    }
}

private fun headline(summary: WeeklySummary): String {
    val days = "${summary.daysActive} ${if (summary.daysActive == 1) "day" else "days"} in the Word"
    if (summary.versesExplored <= 0) return days
    return "$days, ${summary.versesExplored} ${if (summary.versesExplored == 1) "verse" else "verses"} explored"
}

/** Decorative day count + Mon…Sun bars (hidden from TalkBack; the headline says it). */
@Composable
private fun MiniCard(summary: WeeklySummary) {
    Column(
        modifier = Modifier
            .size(width = 66.dp, height = 104.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(RecapBackground)
            .border(1.dp, Color(0xFFECE6D6), RoundedCornerShape(8.dp))
            .padding(horizontal = 7.dp, vertical = 8.dp)
            .clearAndSetSemantics {},
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text("${summary.daysActive}", fontFamily = ScriptureFontFamily, fontSize = 26.sp, color = SeekColors.TextPrimary)
        Text(if (summary.daysActive == 1) "day" else "days", fontSize = 9.sp, color = SeekColors.TextSecondary)
        Spacer(Modifier.weight(1f))
        Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            summary.activeDays.forEach { active ->
                Box(
                    Modifier
                        .weight(1f)
                        .height(5.dp)
                        .background(if (active) SeekColors.Sage else Color(0xFFDDE1D8), CircleShape),
                )
            }
        }
    }
}
