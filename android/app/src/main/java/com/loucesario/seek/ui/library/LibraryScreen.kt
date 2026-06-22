package com.loucesario.seek.ui.library

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.loucesario.seek.cards.CardRenderer
import com.loucesario.seek.cards.CardTemplates
import com.loucesario.seek.data.local.entity.FavoriteVerseEntity
import com.loucesario.seek.data.local.entity.SavedCardEntity
import com.loucesario.seek.data.local.entity.SavedPrayerEntity
import com.loucesario.seek.ui.components.GuestGate
import com.loucesario.seek.ui.theme.ScriptureTextStyle
import com.loucesario.seek.ui.theme.SeekColors

private val TABS = listOf("Cards", "Favorites", "History")

@Composable
fun LibraryScreen(
    isGuest: Boolean,
    onOpenCard: (SavedCardEntity) -> Unit,
    vm: LibraryViewModel = viewModel(),
) {
    if (isGuest) {
        GuestGate(title = "Sign in to save", message = "Save verse cards, favorites, and your conversations.")
        return
    }

    var tab by remember { mutableIntStateOf(0) }
    val cards by vm.cards.collectAsStateWithLifecycle(emptyList())
    val favorites by vm.favorites.collectAsStateWithLifecycle(emptyList())
    val prayers by vm.prayers.collectAsStateWithLifecycle(emptyList())
    val conversations by vm.conversations.collectAsStateWithLifecycle(emptyList())

    Column(Modifier.fillMaxSize().background(SeekColors.Background)) {
        Text(
            "Library", fontSize = 26.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary,
            modifier = Modifier.padding(start = 20.dp, top = 16.dp, bottom = 8.dp),
        )
        TabRow(selectedTabIndex = tab, containerColor = SeekColors.Background, contentColor = SeekColors.Sage) {
            TABS.forEachIndexed { i, title ->
                Tab(selected = tab == i, onClick = { tab = i }, text = { Text(title) })
            }
        }
        when (tab) {
            0 -> CardsTab(cards, onOpenCard, onDeleteCard = vm::deleteCard)
            1 -> FavoritesTab(favorites, prayers)
            else -> HistoryTab(conversations.map { it.conversation.summary ?: "Conversation" })
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun CardsTab(
    cards: List<SavedCardEntity>,
    onOpenCard: (SavedCardEntity) -> Unit,
    onDeleteCard: (SavedCardEntity) -> Unit,
) {
    if (cards.isEmpty()) { Empty("No cards yet", "Tap a verse to create your first card."); return }
    var pendingDelete by remember { mutableStateOf<SavedCardEntity?>(null) }

    LazyVerticalGrid(
        columns = GridCells.Fixed(2),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(cards, key = { it.id }) { card ->
            val bmp = remember(card.id, card.templateId, card.contextNote) {
                CardRenderer.render(
                    CardTemplates.byId(card.templateId), card.verseText, card.verseReference,
                    card.contextNote,
                )
            }
            Image(
                bitmap = bmp.asImageBitmap(),
                contentDescription = card.verseReference,
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(9f / 16f)
                    .clip(RoundedCornerShape(10.dp))
                    .combinedClickable(
                        onClick = { onOpenCard(card) },
                        onLongClick = { pendingDelete = card },
                    ),
            )
        }
    }

    pendingDelete?.let { card ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            containerColor = SeekColors.Surface,
            title = { Text("Delete this card?", color = SeekColors.TextPrimary) },
            text = {
                Text(
                    "This removes \"${card.verseReference}\" from your library. Any copy already saved to your photos is untouched.",
                    color = SeekColors.TextSecondary,
                )
            },
            confirmButton = {
                TextButton(onClick = { onDeleteCard(card); pendingDelete = null }) {
                    Text("Delete", color = Color(0xFFC5221F), fontWeight = FontWeight.SemiBold)
                }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = null }) {
                    Text("Cancel", color = SeekColors.TextSecondary)
                }
            },
        )
    }
}

private val FAVORITE_FILTERS = listOf("All", "Verses", "Prayers")

@Composable
private fun FavoritesTab(verses: List<FavoriteVerseEntity>, prayers: List<SavedPrayerEntity>) {
    if (verses.isEmpty() && prayers.isEmpty()) { Empty("No favorites yet", "Heart a verse or save a prayer to find it here."); return }
    var filter by remember { mutableIntStateOf(0) } // 0 All · 1 Verses · 2 Prayers

    Column(Modifier.fillMaxSize()) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            FAVORITE_FILTERS.forEachIndexed { i, label ->
                val selected = filter == i
                Surface(
                    color = if (selected) SeekColors.Sage else SeekColors.Sage.copy(alpha = 0.10f),
                    shape = RoundedCornerShape(20.dp),
                    modifier = Modifier.clickable { filter = i },
                ) {
                    Text(
                        label, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                        color = if (selected) SeekColors.Surface else SeekColors.Sage,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    )
                }
            }
        }
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp).padding(bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            if (filter != 2) verses.forEach { v -> VerseFavoriteRow(v) }
            if (filter != 1) prayers.forEach { p -> PrayerFavoriteRow(p) }
        }
    }
}

@Composable
private fun VerseFavoriteRow(v: FavoriteVerseEntity) {
    Surface(color = SeekColors.Surface, shape = RoundedCornerShape(12.dp), modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp)) {
            Text(v.text, style = ScriptureTextStyle.copy(fontSize = 16.sp), color = SeekColors.TextPrimary)
            Text(v.reference, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = SeekColors.Sage)
        }
    }
}

@Composable
private fun PrayerFavoriteRow(p: SavedPrayerEntity) {
    Surface(color = SeekColors.Surface, shape = RoundedCornerShape(12.dp), modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp)) {
            Surface(color = SeekColors.LightGold, shape = RoundedCornerShape(8.dp)) {
                Text(
                    "PRAYER", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = SeekColors.Gold,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp),
                )
            }
            Spacer(Modifier.height(8.dp))
            Text(p.text, style = ScriptureTextStyle.copy(fontSize = 16.sp), color = SeekColors.TextPrimary)
        }
    }
}

@Composable
private fun HistoryTab(summaries: List<String>) {
    if (summaries.isEmpty()) { Empty("No conversations yet", "Your chat history will appear here."); return }
    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        summaries.forEach { s ->
            Surface(color = SeekColors.Surface, shape = RoundedCornerShape(12.dp), modifier = Modifier.fillMaxWidth()) {
                Text(s, fontSize = 15.sp, color = SeekColors.TextPrimary, modifier = Modifier.padding(16.dp))
            }
        }
    }
}

@Composable
private fun Empty(title: String, message: String) {
    Box(Modifier.fillMaxSize().padding(32.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(title, fontSize = 18.sp, fontWeight = FontWeight.SemiBold, color = SeekColors.TextPrimary)
            Text(message, fontSize = 14.sp, color = SeekColors.TextSecondary, modifier = Modifier.padding(top = 6.dp))
        }
    }
}
