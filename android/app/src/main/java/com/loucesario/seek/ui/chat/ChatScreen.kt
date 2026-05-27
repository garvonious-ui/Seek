package com.loucesario.seek.ui.chat

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
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
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
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.loucesario.seek.data.remote.dto.VerseDto
import com.loucesario.seek.data.remote.dto.WorshipSongDto
import com.loucesario.seek.ui.components.GuestGate
import com.loucesario.seek.ui.theme.ScriptureTextStyle
import com.loucesario.seek.ui.theme.SeekColors

@Composable
fun ChatScreen(
    isGuest: Boolean,
    onCreateCard: (String, String) -> Unit,
    vm: ChatViewModel = viewModel(),
) {
    if (isGuest) {
        GuestGate(title = "Sign in to chat", message = "Create a free account to talk through what's on your heart.")
        return
    }

    val items by vm.items.collectAsStateWithLifecycle()
    val loading by vm.loading.collectAsStateWithLifecycle()
    var input by remember { mutableStateOf("") }
    val listState = rememberLazyListState()

    LaunchedEffect(items.size, loading) {
        val count = items.size + if (loading) 1 else 0
        if (count > 0) listState.animateScrollToItem(count - 1)
    }

    Column(
        modifier = Modifier.fillMaxSize().background(SeekColors.Background).imePadding(),
    ) {
        if (items.isEmpty()) {
            Box(Modifier.weight(1f).fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                Text(
                    "What's on your heart?",
                    fontSize = 18.sp, color = SeekColors.TextSecondary,
                )
            }
        } else {
            LazyColumn(
                state = listState,
                modifier = Modifier.weight(1f).fillMaxWidth(),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(items, key = { it.id }) { item -> ChatRow(item, onCreateCard) }
                if (loading) {
                    item("loading") {
                        Row(Modifier.padding(8.dp)) {
                            CircularProgressIndicator(color = SeekColors.Sage, modifier = Modifier.size(22.dp))
                        }
                    }
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
                    placeholder = { Text("Share what's on your heart…") },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(24.dp),
                    maxLines = 4,
                )
                IconButton(
                    onClick = { vm.sendMessage(input); input = "" },
                    enabled = !loading && input.isNotBlank(),
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.Send,
                        contentDescription = "Send",
                        tint = if (input.isNotBlank() && !loading) SeekColors.Sage else SeekColors.TextTertiary,
                    )
                }
            }
        }
    }
}

@Composable
private fun ChatRow(item: ChatItem, onCreateCard: (String, String) -> Unit) {
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

        is ChatItem.Intro -> Text(item.text, fontSize = 16.sp, color = SeekColors.TextPrimary)

        is ChatItem.Verses -> Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            item.verses.forEach { v -> VerseCard(v, onTap = { onCreateCard(v.text, v.reference) }) }
        }

        is ChatItem.Prayer -> CardBox(bg = SeekColors.LightGold) {
            Text("PRAYER", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = SeekColors.Gold)
            Spacer(Modifier.height(6.dp))
            Text(item.text, style = ScriptureTextStyle.copy(fontSize = 17.sp), color = SeekColors.TextPrimary)
        }

        is ChatItem.Song -> SongCard(item.song)

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
private fun VerseCard(verse: VerseDto, onTap: () -> Unit) {
    CardBox(bg = SeekColors.Surface, onClick = onTap) {
        Text(verse.text, style = ScriptureTextStyle, color = SeekColors.TextPrimary)
        Spacer(Modifier.height(8.dp))
        Text(verse.reference, fontSize = 14.sp, fontWeight = FontWeight.Medium, color = SeekColors.Sage)
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
    CardBox(bg = SeekColors.Surface) {
        Text("WORSHIP", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = SeekColors.MidSage)
        Spacer(Modifier.height(6.dp))
        Text(song.title, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary)
        Text(song.artist, fontSize = 14.sp, color = SeekColors.TextSecondary)
        song.context?.takeIf { it.isNotBlank() }?.let {
            Spacer(Modifier.height(6.dp))
            Text(it, fontSize = 13.sp, color = SeekColors.TextSecondary)
        }
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
