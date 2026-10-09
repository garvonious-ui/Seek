package com.loucesario.seek.ui.chat

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
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
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.loucesario.seek.data.SeekPrefs
import com.loucesario.seek.data.remote.dto.ActionStepDto
import com.loucesario.seek.data.remote.dto.VerseDto
import com.loucesario.seek.data.remote.dto.WorshipSongDto
import com.loucesario.seek.ui.components.CopyButton
import com.loucesario.seek.ui.components.GuestGate
import com.loucesario.seek.ui.components.verseCopyText
import com.loucesario.seek.ui.theme.ScriptureTextStyle
import com.loucesario.seek.ui.theme.SeekColors

@Composable
fun ChatScreen(
    isGuest: Boolean,
    onCreateCard: (String, String, String?) -> Unit,
    vm: ChatViewModel = viewModel(),
) {
    if (isGuest) {
        GuestGate(title = "Sign in to chat", message = "Create a free account to talk through what's on your heart.")
        return
    }

    val items by vm.items.collectAsStateWithLifecycle()
    val loading by vm.loading.collectAsStateWithLifecycle()
    val favoritedRefs by vm.favoritedRefs.collectAsStateWithLifecycle()
    val savedPrayers by vm.savedPrayerTexts.collectAsStateWithLifecycle()
    val online by com.loucesario.seek.SeekApplication.instance.connectivity.isOnline
        .collectAsStateWithLifecycle(true)
    var input by remember { mutableStateOf("") }
    val listState = rememberLazyListState()

    // A response is regenerate-able once it's complete and we're idle.
    val canRegen = !loading && items.isNotEmpty() &&
        items.last().let { it !is ChatItem.UserBubble && it !is ChatItem.ErrorMsg && it !is ChatItem.RateLimit }

    // Keep the chat's translation in sync with the user's saved preference.
    val ctx = LocalContext.current
    val seekPrefs = remember(ctx) { SeekPrefs(ctx) }
    val translationPref by seekPrefs.translation.collectAsStateWithLifecycle("NLT")
    LaunchedEffect(translationPref) { vm.translation = translationPref }

    // Consume a message handed off from Home (quick prompt / free-text input).
    LaunchedEffect(Unit) {
        vm.translation = seekPrefs.translationOnce()
        ChatDraft.consume()?.let { vm.sendMessage(it) }
    }

    LaunchedEffect(items.size, loading) {
        val count = items.size + if (loading) 1 else 0
        if (count > 0) listState.animateScrollToItem(count - 1)
    }

    Column(
        modifier = Modifier.fillMaxSize().background(SeekColors.Background).imePadding(),
    ) {
        if (items.isEmpty()) {
            ChatEmptyState(
                modifier = Modifier.weight(1f),
                onPick = { vm.sendMessage(it) },
            )
        } else {
            LazyColumn(
                state = listState,
                modifier = Modifier.weight(1f).fillMaxWidth(),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(items, key = { it.id }) { item ->
                    ChatRow(
                        item = item,
                        onCreateCard = onCreateCard,
                        favoritedRefs = favoritedRefs,
                        savedPrayers = savedPrayers,
                        onToggleFavorite = vm::toggleFavorite,
                        onTogglePrayer = vm::togglePrayer,
                    )
                }
                if (loading) {
                    item("loading") {
                        Row(Modifier.padding(8.dp)) {
                            CircularProgressIndicator(color = SeekColors.Sage, modifier = Modifier.size(22.dp))
                        }
                    }
                }
            }
        }

        // Offline banner
        if (!online) {
            Surface(color = SeekColors.SurfaceMuted, modifier = Modifier.fillMaxWidth()) {
                Text(
                    "You're offline. Scripture chat will resume when you reconnect.",
                    fontSize = 13.sp, color = SeekColors.TextSecondary,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                )
            }
        }

        // Regenerate bar — ask for different scriptures on the same topic.
        if (canRegen && online) {
            Surface(color = SeekColors.Background, modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
                    horizontalArrangement = Arrangement.Center,
                ) {
                    Text(
                        "↻  Show different scriptures",
                        fontSize = 14.sp, fontWeight = FontWeight.Medium, color = SeekColors.Sage,
                        modifier = Modifier.clickable { vm.regenerate() }.padding(8.dp),
                    )
                }
            }
        }

        // Input bar
        Surface(color = SeekColors.Surface, shadowElevation = 8.dp) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedTextField(
                    value = input,
                    onValueChange = { input = it },
                    placeholder = { Text(if (online) "Share what's on your heart…" else "Waiting for connection…") },
                    enabled = online,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(24.dp),
                    maxLines = 4,
                )
                IconButton(
                    onClick = { vm.sendMessage(input); input = "" },
                    enabled = !loading && input.isNotBlank() && online,
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.Send,
                        contentDescription = "Send",
                        tint = if (input.isNotBlank() && !loading && online) SeekColors.Sage else SeekColors.TextTertiary,
                    )
                }
            }
        }
    }
}

@Composable
private fun ChatRow(
    item: ChatItem,
    onCreateCard: (String, String, String?) -> Unit,
    favoritedRefs: Set<String>,
    savedPrayers: Set<String>,
    onToggleFavorite: (VerseDto) -> Unit,
    onTogglePrayer: (String) -> Unit,
) {
    when (item) {
        is ChatItem.UserBubble -> Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            Surface(
                color = SeekColors.Sage,
                shape = RoundedCornerShape(18.dp),
                modifier = Modifier.widthIn(max = 300.dp),
            ) {
                Text(item.text, color = SeekColors.Surface, fontSize = 16.sp, modifier = Modifier.padding(14.dp))
            }
        }

        // Copied as shown — Android renders the intro as plain text, not markdown.
        is ChatItem.Intro -> Column {
            Text(item.text, fontSize = 16.sp, color = SeekColors.TextPrimary)
            Spacer(Modifier.height(6.dp))
            CopyButton(text = item.text, tint = SeekColors.TextSecondary)
        }

        is ChatItem.Verses -> Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            item.verses.forEach { v ->
                VerseCard(
                    verse = v,
                    isFavorite = favoritedRefs.contains(v.reference),
                    onTap = { onCreateCard(v.text, v.reference, v.context) },
                    onToggleFavorite = { onToggleFavorite(v) },
                )
            }
        }

        is ChatItem.Prayer -> CardBox(bg = SeekColors.LightGold) {
            Text("PRAYER", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = SeekColors.Gold)
            Spacer(Modifier.height(6.dp))
            Text(item.text, style = ScriptureTextStyle.copy(fontSize = 17.sp), color = SeekColors.TextPrimary)
            Spacer(Modifier.height(10.dp))
            val saved = savedPrayers.contains(item.text)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.clickable { onTogglePrayer(item.text) },
                ) {
                    Icon(
                        imageVector = if (saved) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                        contentDescription = if (saved) "Saved" else "Save prayer",
                        tint = if (saved) SeekColors.Gold else SeekColors.TextTertiary,
                        modifier = Modifier.size(20.dp),
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(if (saved) "Saved" else "Save prayer", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = SeekColors.Gold)
                }
                Spacer(Modifier.width(18.dp))
                CopyButton(text = item.text)
                Spacer(Modifier.weight(1f))
                Text(
                    "Make a card →", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = SeekColors.Sage,
                    modifier = Modifier.clickable { onCreateCard(item.text, "A Prayer", null) },
                )
            }
        }

        is ChatItem.Song -> SongCard(item.song)

        is ChatItem.Action -> ActionCard(item.action)

        is ChatItem.FollowUp -> Text(
            item.text, fontSize = 15.sp, fontStyle = FontStyle.Italic, color = SeekColors.TextSecondary,
        )

        is ChatItem.RateLimit -> CardBox(bg = SeekColors.SurfaceMuted) {
            Text(item.message, fontSize = 14.sp, color = SeekColors.TextPrimary)
            Spacer(Modifier.height(4.dp))
            Text("Resets at midnight, your local time.", fontSize = 12.sp, color = SeekColors.TextSecondary)
        }

        is ChatItem.ErrorMsg -> Text(item.text, fontSize = 14.sp, color = SeekColors.Warning)
    }
}

@Composable
private fun VerseCard(verse: VerseDto, isFavorite: Boolean, onTap: () -> Unit, onToggleFavorite: () -> Unit) {
    CardBox(bg = SeekColors.Surface, onClick = onTap) {
        Text(verse.text, style = ScriptureTextStyle, color = SeekColors.TextPrimary)
        Spacer(Modifier.height(8.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                verse.reference, fontSize = 14.sp, fontWeight = FontWeight.Medium, color = SeekColors.Sage,
                modifier = Modifier.weight(1f),
            )
            CopyButton(
                text = verseCopyText(verse.text, verse.reference),
                iconOnly = true,
                tint = SeekColors.TextTertiary,
            )
            Spacer(Modifier.width(16.dp))
            Icon(
                imageVector = if (isFavorite) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                contentDescription = if (isFavorite) "Unfavorite" else "Favorite",
                tint = if (isFavorite) SeekColors.Gold else SeekColors.TextTertiary,
                modifier = Modifier.size(22.dp).clickable { onToggleFavorite() },
            )
        }
        verse.context?.takeIf { it.isNotBlank() }?.let {
            Spacer(Modifier.height(6.dp))
            Text(it, fontSize = 13.sp, color = SeekColors.TextSecondary)
        }
        Spacer(Modifier.height(8.dp))
        Text("Tap to make a card →", fontSize = 12.sp, color = SeekColors.MidSage)
    }
}

@Composable
private fun SongCard(song: WorshipSongDto) {
    val context = LocalContext.current
    val query = Uri.encode("${song.title} ${song.artist}")
    CardBox(bg = SeekColors.Surface) {
        Text("WORSHIP", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = SeekColors.MidSage)
        Spacer(Modifier.height(6.dp))
        Text(song.title, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary)
        Text(song.artist, fontSize = 14.sp, color = SeekColors.TextSecondary)
        song.context?.takeIf { it.isNotBlank() }?.let {
            Spacer(Modifier.height(6.dp))
            Text(it, fontSize = 13.sp, color = SeekColors.TextSecondary)
        }
        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(22.dp)) {
            Text(
                "Apple Music", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = SeekColors.Sage,
                modifier = Modifier.clickable { openUrl(context, "https://music.apple.com/search?term=$query") },
            )
            Text(
                "Spotify", fontSize = 13.sp, fontWeight = FontWeight.Medium,
                color = androidx.compose.ui.graphics.Color(0xFF1DB954),
                modifier = Modifier.clickable {
                    // Prefer the Spotify app; fall back to web search if it isn't installed.
                    try {
                        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("spotify:search:$query")))
                    } catch (e: ActivityNotFoundException) {
                        openUrl(context, "https://open.spotify.com/search/$query")
                    }
                },
            )
        }
    }
}

@Composable
private fun ActionCard(action: ActionStepDto) {
    CardBox(bg = SeekColors.Sage.copy(alpha = 0.08f)) {
        Text(action.title, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.Sage)
        Spacer(Modifier.height(10.dp))
        action.steps.forEachIndexed { i, step ->
            Row(verticalAlignment = Alignment.Top) {
                Box(
                    modifier = Modifier.size(20.dp).background(SeekColors.Sage, RoundedCornerShape(10.dp)),
                    contentAlignment = Alignment.Center,
                ) {
                    Text("${i + 1}", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = SeekColors.Surface)
                }
                Spacer(Modifier.width(10.dp))
                Text(step, fontSize = 15.sp, color = SeekColors.TextPrimary, modifier = Modifier.weight(1f))
            }
            if (i < action.steps.size - 1) Spacer(Modifier.height(8.dp))
        }
        action.reason.takeIf { it.isNotBlank() }?.let {
            Spacer(Modifier.height(10.dp))
            Text(it, fontSize = 13.sp, fontStyle = FontStyle.Italic, color = SeekColors.TextSecondary)
        }
        Spacer(Modifier.height(10.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            CopyButton(text = actionCopyText(action))
        }
    }
}

/** Clipboard text for an action card — identical to iOS: title, numbered steps, blank line, reason. */
private fun actionCopyText(action: ActionStepDto): String {
    val steps = action.steps.mapIndexed { i, step -> "${i + 1}. $step" }
    return (listOf(action.title) + steps + listOf("", action.reason)).joinToString("\n")
}

private fun openUrl(context: Context, url: String) {
    try {
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    } catch (e: ActivityNotFoundException) {
        // No handler available — silently ignore.
    }
}

@Composable
private fun CardBox(
    bg: androidx.compose.ui.graphics.Color,
    onClick: (() -> Unit)? = null,
    content: @Composable androidx.compose.foundation.layout.ColumnScope.() -> Unit,
) {
    val base = Modifier.fillMaxWidth()
    val mod = if (onClick != null) base.clickable(onClick = onClick) else base
    Surface(color = bg, shape = RoundedCornerShape(12.dp), shadowElevation = 1.dp, modifier = mod) {
        Column(Modifier.padding(16.dp), content = content)
    }
}

/** Example prompts offered on the empty chat screen. */
private val SUGGESTION_PROMPTS = listOf(
    "I'm feeling grateful today",
    "I need strength for something hard",
    "I just want to praise God",
)

@Composable
private fun ChatEmptyState(modifier: Modifier, onPick: (String) -> Unit) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(24.dp))
        Text(
            "Share what's on your heart",
            fontSize = 20.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            "Tell me what you're going through — joy, gratitude, struggle, or seeking — and I'll find scripture for your moment.",
            fontSize = 14.sp, color = SeekColors.TextSecondary, textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(20.dp))
        SUGGESTION_PROMPTS.forEach { prompt ->
            Surface(
                color = SeekColors.Sage.copy(alpha = 0.08f),
                shape = RoundedCornerShape(20.dp),
                modifier = Modifier.padding(vertical = 5.dp).clickable { onPick(prompt) },
            ) {
                Text(
                    prompt,
                    fontSize = 15.sp, color = SeekColors.Sage,
                    modifier = Modifier.padding(horizontal = 18.dp, vertical = 12.dp),
                )
            }
        }
    }
}
