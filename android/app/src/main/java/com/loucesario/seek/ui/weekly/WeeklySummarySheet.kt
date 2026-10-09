package com.loucesario.seek.ui.weekly

import android.content.Intent
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.ProvideTextStyle
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.loucesario.seek.cards.CardExport
import com.loucesario.seek.cards.WeeklyCardRenderer
import com.loucesario.seek.data.WeeklySummary
import com.loucesario.seek.ui.components.CopyButton
import com.loucesario.seek.ui.components.verseCopyText
import com.loucesario.seek.ui.theme.ScriptureFontFamily
import com.loucesario.seek.ui.theme.ScriptureTextStyle
import com.loucesario.seek.ui.theme.SeekColors
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

internal val RecapBackground = Color(0xFFFAF7F0)
internal val RecapDarkGold = Color(0xFF7A5C17)

/** Natural line heights (not bodyLarge's fixed 24sp) so the layout matches iOS. */
internal val RecapTextStyle = TextStyle(fontFamily = FontFamily.SansSerif)

private val DAY_LETTERS = listOf("M", "T", "W", "T", "F", "S", "S")

/**
 * The in-app weekly recap ("Morning" — stats-led, light) as a full-height
 * sheet. "Share your week" exports the dark, verse-led [WeeklyCardRenderer]
 * card at 1080x1920 through the system share sheet. Port of the iOS
 * WeeklySummaryView.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WeeklySummarySheet(summary: WeeklySummary, onDismiss: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        // Full height, but below the status bar (the default insets are bottom-only).
        modifier = Modifier.statusBarsPadding(),
        sheetState = sheetState,
        containerColor = RecapBackground,
        dragHandle = null,
    ) {
        ProvideTextStyle(RecapTextStyle) {
            WeeklySummaryContent(
                summary = summary,
                onDone = {
                    scope.launch { sheetState.hide() }.invokeOnCompletion {
                        if (!sheetState.isVisible) onDismiss()
                    }
                },
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun WeeklySummaryContent(summary: WeeklySummary, onDone: () -> Unit) {
    Column(Modifier.fillMaxSize()) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp), horizontalArrangement = Arrangement.End) {
            TextButton(onClick = onDone) {
                Text("Done", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Sage)
            }
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(start = 24.dp, end = 24.dp, top = 8.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(26.dp),
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    "YOUR WEEK WITH SEEK",
                    fontSize = 12.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.8.sp, color = SeekColors.Sage,
                )
                Text(summary.dateRange, fontSize = 15.sp, color = SeekColors.TextSecondary)
            }

            Column(Modifier.semantics(mergeDescendants = true) {}, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Row {
                    Text(
                        "${summary.daysActive}", Modifier.alignByBaseline(),
                        fontFamily = ScriptureFontFamily, fontSize = 104.sp, color = SeekColors.TextPrimary,
                    )
                    Spacer(Modifier.width(10.dp))
                    Text(
                        if (summary.daysActive == 1) "day" else "days", Modifier.alignByBaseline(),
                        fontFamily = ScriptureFontFamily, fontSize = 34.sp, color = SeekColors.TextPrimary,
                    )
                }
                Text("spent in the Word this week", fontSize = 17.sp, color = Color(0xFF4B5563))
            }

            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                DayDots(summary)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Outlined.LocalFireDepartment, contentDescription = null,
                        tint = SeekColors.Gold, modifier = Modifier.size(18.dp),
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(streakLine(summary), fontSize = 15.sp, color = RecapDarkGold)
                }
            }

            HeldVerseCard(summary)

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Stat(summary.versesExplored, "verse explored", "verses explored")
                Stat(summary.prayersSaved, "prayer saved", "prayers saved")
                Stat(summary.cardsMade, "card made", "cards made")
            }

            if (summary.themes.isNotEmpty()) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        "WHAT WAS ON YOUR HEART",
                        fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.6.sp,
                        color = SeekColors.TextSecondary,
                    )
                    // Wraps instead of truncating when three long themes don't fit one line.
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        summary.themes.forEach { theme ->
                            Text(
                                theme, fontSize = 15.sp, color = Color(0xFF3F5A42),
                                modifier = Modifier
                                    .background(SeekColors.Sage.copy(alpha = 0.12f), CircleShape)
                                    .padding(horizontal = 14.dp, vertical = 6.dp),
                            )
                        }
                    }
                }
            }
        }

        ShareBar(summary)
    }
}

private fun streakLine(summary: WeeklySummary): String {
    if (summary.isQuiet) return "Every moment counts. Pick up where you left off."
    val streak = "${summary.streak}-day streak"
    return if (summary.streak >= summary.longestStreak) "$streak — your longest yet"
    else "$streak — your longest is ${summary.longestStreak}"
}

/** M…S circles; read as one "6 of 7 days active this week" by TalkBack. */
@Composable
private fun DayDots(summary: WeeklySummary) {
    Row(
        modifier = Modifier.fillMaxWidth().clearAndSetSemantics {
            contentDescription = "${summary.daysActive} of 7 days active this week"
        },
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        DAY_LETTERS.zip(summary.activeDays).forEach { (letter, active) ->
            Box(Modifier.weight(1f).height(40.dp), contentAlignment = Alignment.Center) {
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .aspectRatio(1f, matchHeightConstraintsFirst = true)
                        .then(
                            if (active) Modifier.background(SeekColors.Sage, CircleShape)
                            else Modifier.border(1.5.dp, Color(0xFFD5D9D0), CircleShape)
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        letter,
                        fontSize = 15.sp,
                        fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal,
                        color = if (active) Color.White else SeekColors.TextTertiary,
                    )
                }
            }
        }
    }
}

@Composable
private fun HeldVerseCard(summary: WeeklySummary) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = SeekColors.Surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(
                "THE VERSE YOU HELD ONTO",
                fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.6.sp, color = RecapDarkGold,
            )
            Text(summary.verseText, style = ScriptureTextStyle, color = SeekColors.TextPrimary)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "— ${summary.verseReference}",
                    fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Sage,
                    modifier = Modifier.weight(1f),
                )
                CopyButton(text = verseCopyText(summary.verseText, summary.verseReference))
            }
        }
    }
}

@Composable
private fun RowScope.Stat(value: Int, singular: String, plural: String) {
    Column(Modifier.weight(1f).semantics(mergeDescendants = true) {}, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text("$value", fontFamily = ScriptureFontFamily, fontSize = 34.sp, color = SeekColors.TextPrimary)
        Text(if (value == 1) singular else plural, fontSize = 13.sp, color = SeekColors.TextSecondary)
    }
}

/** Live thumbnail of the share card + "Share your week" (renders the 1080x1920 PNG on tap). */
@Composable
private fun ShareBar(summary: WeeklySummary) {
    val context = LocalContext.current
    val density = LocalDensity.current
    val scope = rememberCoroutineScope()
    // Same renderer as the export, drawn at thumbnail size so it stays crisp.
    val thumbnail = remember(summary, density) {
        with(density) { WeeklyCardRenderer.render(summary, 45.dp.roundToPx(), 80.dp.roundToPx()) }
    }

    Column {
        HorizontalDivider(color = SeekColors.Divider)
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Image(
                bitmap = thumbnail.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier.size(width = 45.dp, height = 80.dp).clip(RoundedCornerShape(6.dp)),
            )
            Button(
                onClick = {
                    scope.launch {
                        val share = withContext(Dispatchers.IO) {
                            CardExport.shareIntent(context, WeeklyCardRenderer.render(summary))
                        }
                        context.startActivity(Intent.createChooser(share, "Share your week"))
                    }
                },
                modifier = Modifier.weight(1f).height(50.dp),
                shape = RoundedCornerShape(24.dp),
                colors = ButtonDefaults.buttonColors(containerColor = SeekColors.Sage),
            ) {
                Icon(Icons.Outlined.Share, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text("Share your week", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Surface)
            }
        }
    }
}
