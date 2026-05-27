package com.loucesario.seek.notifications

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.notifDataStore by preferencesDataStore(name = "notif_prefs")

/**
 * Local persistence for notification toggles. Default times match iOS:
 * daily verse 7am, streak nudge 7pm. (Supabase `notification_settings` sync is
 * deferred — local scheduling fully satisfies the daily-reminder goal.)
 */
class NotificationPrefs(private val context: Context) {
    private val verseKey = booleanPreferencesKey("daily_verse_enabled")
    private val streakKey = booleanPreferencesKey("streak_enabled")

    val dailyVerseEnabled: Flow<Boolean> = context.notifDataStore.data.map { it[verseKey] ?: false }
    val streakEnabled: Flow<Boolean> = context.notifDataStore.data.map { it[streakKey] ?: false }

    suspend fun setDailyVerse(enabled: Boolean) {
        context.notifDataStore.edit { it[verseKey] = enabled }
        if (enabled) NotificationScheduler.schedule(context, NotificationScheduler.TYPE_VERSE, 7, 0)
        else NotificationScheduler.cancel(context, NotificationScheduler.TYPE_VERSE)
    }

    suspend fun setStreak(enabled: Boolean) {
        context.notifDataStore.edit { it[streakKey] = enabled }
        if (enabled) NotificationScheduler.schedule(context, NotificationScheduler.TYPE_STREAK, 19, 0)
        else NotificationScheduler.cancel(context, NotificationScheduler.TYPE_STREAK)
    }

    companion object {
        const val DAILY_VERSE_TIME = "7:00 AM"
        const val STREAK_TIME = "7:00 PM"
    }
}
