package com.loucesario.seek.data

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Mirrors the iOS StreakManager: a streak increments on a consecutive day, keeps
 * a 1-day grace window, and resets on a longer gap. Idempotent per local day.
 * Backed by [SeekPrefs] (epoch-day Long) rather than SwiftData.
 */
object StreakManager {
    private val MILESTONES = listOf(7, 30, 90, 365)

    /** Records today's activity and returns the resulting streak count. */
    suspend fun recordActivity(prefs: SeekPrefs): Int {
        val date = LocalDate.now()
        val today = date.toEpochDay()
        recordActiveDay(prefs, date)
        val snap = prefs.streakSnapshot()
        val last = snap.lastActiveDay
        if (last == today) return snap.count // already recorded today

        val newCount = when (last) {
            null -> 1
            today - 1L -> snap.count + 1 // consecutive day
            today - 2L -> snap.count + 1 // grace: missed exactly one day (mirrors iOS)
            else -> 1                    // streak broken
        }
        val newLongest = maxOf(newCount, snap.longest)
        prefs.writeStreak(newCount, newLongest, today)
        return newCount
    }

    fun checkMilestone(streak: Int): Int? = MILESTONES.firstOrNull { it == streak }

    // Active-day log. The streak only keeps the last active day + a running
    // count, which can't answer "which days this week?". The weekly summary
    // reads this log (plus timestamps on chats, favorites, prayers and cards
    // for days before the log existed). Day keys are local-calendar "yyyy-MM-dd".

    private const val ACTIVE_DAYS_RETENTION = 70 // ~10 weeks

    fun dayKey(date: LocalDate): String = date.toString() // ISO-8601, yyyy-MM-dd

    fun dayKey(epochMillis: Long): String =
        dayKey(Instant.ofEpochMilli(epochMillis).atZone(ZoneId.systemDefault()).toLocalDate())

    suspend fun recordActiveDay(prefs: SeekPrefs, date: LocalDate = LocalDate.now()) {
        prefs.addActiveDay(dayKey(date), ACTIVE_DAYS_RETENTION)
    }

    suspend fun activeDayKeys(prefs: SeekPrefs): Set<String> = prefs.activeDayKeys()
}
