package com.loucesario.seek.data

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.seekDataStore by preferencesDataStore(name = "seek_prefs")

/**
 * App-level preferences stored locally:
 *  - preferred Bible translation (NLT / KJV), mirrored to Supabase profiles
 *  - streak counters (drives the Home capsule; mirrors the iOS StreakManager)
 */
class SeekPrefs(private val context: Context) {
    private val translationKey = stringPreferencesKey("preferred_translation")
    private val streakKey = intPreferencesKey("streak_count")
    private val longestKey = intPreferencesKey("longest_streak")
    private val lastActiveKey = longPreferencesKey("last_active_day") // epoch-day
    private val versesKey = intPreferencesKey("verses_explored")
    private val cardsKey = intPreferencesKey("cards_created")

    val translation: Flow<String> = context.seekDataStore.data.map { it[translationKey] ?: "NLT" }
    val streakCount: Flow<Int> = context.seekDataStore.data.map { it[streakKey] ?: 0 }
    val longestStreak: Flow<Int> = context.seekDataStore.data.map { it[longestKey] ?: 0 }
    val versesExplored: Flow<Int> = context.seekDataStore.data.map { it[versesKey] ?: 0 }
    val cardsCreated: Flow<Int> = context.seekDataStore.data.map { it[cardsKey] ?: 0 }

    suspend fun addVersesExplored(count: Int) {
        context.seekDataStore.edit { it[versesKey] = (it[versesKey] ?: 0) + count }
    }

    suspend fun incrementCardsCreated() {
        context.seekDataStore.edit { it[cardsKey] = (it[cardsKey] ?: 0) + 1 }
    }

    private val topicsKey = stringSetPreferencesKey("onboarding_topics")
    val onboardingTopics: Flow<Set<String>> = context.seekDataStore.data.map { it[topicsKey] ?: emptySet() }

    suspend fun setOnboardingTopics(topics: Set<String>) {
        context.seekDataStore.edit { it[topicsKey] = topics }
    }

    suspend fun setTranslation(value: String) {
        context.seekDataStore.edit { it[translationKey] = value }
    }

    suspend fun translationOnce(): String =
        context.seekDataStore.data.map { it[translationKey] ?: "NLT" }.first()

    /** Streak snapshot for synchronous reads inside recordActivity. */
    suspend fun streakSnapshot(): StreakSnapshot {
        val prefs = context.seekDataStore.data.first()
        return StreakSnapshot(
            count = prefs[streakKey] ?: 0,
            longest = prefs[longestKey] ?: 0,
            lastActiveDay = prefs[lastActiveKey],
        )
    }

    suspend fun writeStreak(count: Int, longest: Int, lastActiveDay: Long) {
        context.seekDataStore.edit {
            it[streakKey] = count
            it[longestKey] = longest
            it[lastActiveKey] = lastActiveDay
        }
    }
}

data class StreakSnapshot(val count: Int, val longest: Int, val lastActiveDay: Long?)
