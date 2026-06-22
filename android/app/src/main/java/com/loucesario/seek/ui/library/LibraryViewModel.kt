package com.loucesario.seek.ui.library

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.loucesario.seek.SeekApplication
import com.loucesario.seek.data.local.ConversationWithMessages
import com.loucesario.seek.data.local.entity.FavoriteVerseEntity
import com.loucesario.seek.data.local.entity.SavedCardEntity
import com.loucesario.seek.data.local.entity.SavedPrayerEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

class LibraryViewModel(app: Application) : AndroidViewModel(app) {
    private val db = (app as SeekApplication).database

    val cards: Flow<List<SavedCardEntity>> = db.savedCardDao().observeAll()
    val favorites: Flow<List<FavoriteVerseEntity>> = db.favoriteVerseDao().observeAll()
    val prayers: Flow<List<SavedPrayerEntity>> = db.savedPrayerDao().observeAll()
    val conversations: Flow<List<ConversationWithMessages>> = db.chatDao().observeConversations()

    fun deleteCard(card: SavedCardEntity) {
        viewModelScope.launch { db.savedCardDao().delete(card) }
    }
}
