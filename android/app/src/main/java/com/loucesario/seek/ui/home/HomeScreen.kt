package com.loucesario.seek.ui.home

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.loucesario.seek.data.remote.dto.DailyVerseDto
import com.loucesario.seek.ui.components.CopyButton
import com.loucesario.seek.ui.components.verseCopyText
import com.loucesario.seek.ui.theme.ScriptureTextStyle
import com.loucesario.seek.ui.theme.SeekColors
import com.loucesario.seek.ui.weekly.WeeklyRecapTile
import com.loucesario.seek.ui.weekly.WeeklySummarySheet

private val QUICK_PROMPTS = listOf("Anxious", "Grateful", "Lonely", "Hopeful", "Tired", "Seeking")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    isGuest: Boolean,
    onOpenProfile: () -> Unit,
    onCreateCard: (String, String) -> Unit,
    onStartChat: (String) -> Unit,
    vm: HomeViewModel = viewModel(),
) {
    val state by vm.state.collectAsStateWithLifecycle()
    val streak by vm.streak.collectAsStateWithLifecycle()
    val recap by vm.recap.collectAsStateWithLifecycle()
    val presentedSummary by vm.presentedSummary.collectAsStateWithLifecycle()
    val online by com.loucesario.seek.SeekApplication.instance.connectivity.isOnline
        .collectAsStateWithLifecycle(true)
    var customPrompt by remember { mutableStateOf("") }

    // Opening Home counts as activity for the day (mirrors iOS). Guests have no streak.
    LaunchedEffect(isGuest) { if (!isGuest) vm.recordActivity() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(SeekColors.Background)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp, vertical = 12.dp),
    ) {
        // Top bar: wordmark + profile
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("Seek", fontSize = 30.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary)
            IconButton(onClick = onOpenProfile) {
                Icon(Icons.Outlined.AccountCircle, "Profile", tint = SeekColors.Sage, modifier = Modifier.size(30.dp))
            }
        }

        if (!isGuest && streak > 0) {
            Spacer(Modifier.height(4.dp))
            // Tapping the streak opens this week so far.
            Surface(
                modifier = Modifier
                    .clip(RoundedCornerShape(20.dp))
                    .clickable(onClickLabel = "Show your week", role = Role.Button, onClick = vm::openCurrentWeek),
                shape = RoundedCornerShape(20.dp),
                color = SeekColors.LightGold,
            ) {
                Text(
                    if (streak == 1) "🔥 1 day streak" else "🔥 $streak day streak",
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
                    fontSize = 13.sp, fontWeight = FontWeight.Medium, color = SeekColors.TextPrimary,
                )
            }
        }

        if (!online) {
            Spacer(Modifier.height(8.dp))
            Surface(shape = RoundedCornerShape(20.dp), color = SeekColors.SurfaceMuted) {
                Text(
                    "Offline",
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
                    fontSize = 12.sp, fontWeight = FontWeight.Medium, color = SeekColors.TextSecondary,
                )
            }
        }

        // "Your week is ready" — Sunday noon through Tuesday (HomeViewModel.loadWeeklyRecap).
        val tileSummary = recap
        if (!isGuest && tileSummary != null) {
            Spacer(Modifier.height(20.dp))
            WeeklyRecapTile(tileSummary, onOpen = vm::openRecap, onDismiss = vm::dismissRecap)
        }

        Spacer(Modifier.height(20.dp))
        Text("TODAY'S VERSE", fontSize = 12.sp, fontWeight = FontWeight.Medium, color = SeekColors.TextSecondary)
        Spacer(Modifier.height(8.dp))

        when (val s = state) {
            is DailyVerseState.Loading -> LoadingCard()
            is DailyVerseState.Loaded -> VerseCard(s.verse, onClick = { onCreateCard(s.verse.text, s.verse.reference) })
            is DailyVerseState.Error -> VerseCard(s.cached, showSavedBadge = true, onClick = { onCreateCard(s.cached.text, s.cached.reference) })
        }
        Spacer(Modifier.height(6.dp))
        Text("Tap the verse to make a card", fontSize = 12.sp, color = SeekColors.TextTertiary)

        // Share with a friend (mirrors iOS Home)
        Spacer(Modifier.height(20.dp))
        val shareCtx = LocalContext.current
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = SeekColors.Sage.copy(alpha = 0.10f),
            modifier = Modifier.fillMaxWidth().clickable {
                val share = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(
                        Intent.EXTRA_TEXT,
                        "I've been using Seek to find scripture for what's on my heart. It's quiet, beautiful, and free. I think you'd love it.\nhttps://play.google.com/store/apps/details?id=com.loucesario.seek",
                    )
                }
                shareCtx.startActivity(Intent.createChooser(share, "Share Seek"))
            },
        ) {
            Box(Modifier.fillMaxWidth().padding(vertical = 12.dp), contentAlignment = Alignment.Center) {
                Text("💛  Share Seek with a friend", fontSize = 14.sp, fontWeight = FontWeight.Medium, color = SeekColors.Sage)
            }
        }

        Spacer(Modifier.height(28.dp))
        Text(
            if (isGuest) "Sign in to talk it through" else "What's on your heart?",
            fontSize = 12.sp, fontWeight = FontWeight.Medium, color = SeekColors.TextSecondary,
        )
        Spacer(Modifier.height(12.dp))
        // Quick prompts — tapping one opens a chat seeded with that feeling.
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            QUICK_PROMPTS.chunked(2).forEach { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                    row.forEach { prompt ->
                        Surface(
                            modifier = Modifier
                                .weight(1f)
                                .height(48.dp)
                                .clickable { onStartChat("I'm dealing with ${prompt.lowercase()}") },
                            shape = RoundedCornerShape(14.dp),
                            color = SeekColors.Surface,
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(prompt, fontSize = 15.sp, color = SeekColors.TextPrimary)
                            }
                        }
                    }
                }
            }
        }

        Spacer(Modifier.height(12.dp))
        // Free-text input — opens a new chat with whatever the user types.
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedTextField(
                value = customPrompt,
                onValueChange = { customPrompt = it },
                placeholder = { Text("What's on your heart?") },
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(14.dp),
                maxLines = 3,
            )
            IconButton(
                onClick = {
                    val msg = customPrompt.trim()
                    if (msg.isNotEmpty()) {
                        onStartChat(msg)
                        customPrompt = ""
                    }
                },
                enabled = customPrompt.isNotBlank(),
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.Send,
                    contentDescription = "Send",
                    tint = if (customPrompt.isNotBlank()) SeekColors.Sage else SeekColors.TextTertiary,
                )
            }
        }
        Spacer(Modifier.height(24.dp))
    }

    presentedSummary?.let { WeeklySummarySheet(it, onDismiss = vm::closeSummary) }
}

@Composable
private fun LoadingCard() {
    Card(
        modifier = Modifier.fillMaxWidth().height(140.dp),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = SeekColors.Surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = SeekColors.Sage)
        }
    }
}

@Composable
private fun VerseCard(verse: DailyVerseDto, showSavedBadge: Boolean = false, onClick: () -> Unit = {}) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = SeekColors.Surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(verse.text, style = ScriptureTextStyle, color = SeekColors.TextPrimary)
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text(verse.reference, fontSize = 14.sp, fontWeight = FontWeight.Medium, color = SeekColors.Sage)
                if (showSavedBadge) {
                    Text("· offline", fontSize = 12.sp, color = SeekColors.TextTertiary)
                }
                Spacer(Modifier.weight(1f))
                CopyButton(
                    text = verseCopyText(verse.text, verse.reference),
                    iconOnly = true,
                    tint = SeekColors.TextTertiary,
                )
            }
        }
    }
}
