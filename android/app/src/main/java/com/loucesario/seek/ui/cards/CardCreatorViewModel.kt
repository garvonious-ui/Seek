package com.loucesario.seek.ui.cards

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.loucesario.seek.SeekApplication
import com.loucesario.seek.data.local.entity.SavedCardEntity
import java.util.UUID

class CardCreatorViewModel(app: Application) : AndroidViewModel(app) {
    private val savedCardDao = (app as SeekApplication).database.savedCardDao()

    suspend fun persist(templateId: String, verseText: String, reference: String, contextNote: String? = null) {
        savedCardDao.upsert(
            SavedCardEntity(
                id = UUID.randomUUID().toString(),
                verseReference = reference,
                verseText = verseText,
                templateId = templateId,
                createdAt = System.currentTimeMillis(),
                isFavorite = false,
                contextNote = contextNote,
            )
        )
    }
}
