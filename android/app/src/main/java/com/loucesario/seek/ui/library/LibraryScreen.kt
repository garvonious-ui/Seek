package com.loucesario.seek.ui.library

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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
    onOpenCard: (String, String) -> Unit,
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
            0 -> CardsTab(cards, onOpenCard)
            1 -> FavoritesTab(favorites, prayers)
            else -> HistoryTab(conversations.map { it.conversation.summary ?: "Conversation" })
        }
    }
}

@Composable
private fun CardsTab(cards: List<SavedCardEntity>, onOpenCard: (String, String) -> Unit) {
    if (cards.isEmpty()) { Empty("No cards yet", "Tap a verse to create your first card."); return }
    LazyVerticalGrid(
        columns = GridCells.Fixed(2),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(cards, key = { it.id }) { card ->
            val bmp = remember(card.id) {
                CardRenderer.render(CardTemplates.byId(card.templateId), card.verseText, card.verseReference)
            }
            Image(
                bitmap = bmp.asImageBitmap(),
                contentDescription = card.verseReference,
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(9f / 16f)
                    .clip(RoundedCornerShape(10.dp))
                    .clickable { onOpenCard(card.verseText, card.verseReference) },
            )
        }
    }
}

@Composable
private fun FavoritesTab(verses: List<FavoriteVerseEntity>, prayers: List<SavedPrayerEntity>) {
    if (verses.isEmpty() && prayers.isEmpty()) { Empty("No favorites yet", "Heart a verse or save a prayer to find it here."); return }
    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        verses.forEach { v ->
            Surface(color = SeekColors.Surface, shape = RoundedCornerShape(12.dp), modifier = Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp)) {
                    Text(v.text, style = ScriptureTextStyle.copy(fontSize = 16.sp), color = SeekColors.TextPrimary)
                    Text(v.reference, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = SeekColors.Sage)
                }
            }
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
