package com.loucesario.seek.data

import java.time.LocalDate

/**
 * Mirrors the iOS StreakManager: a streak increments on a consecutive day, keeps
 * a 1-day grace window, and resets on a longer gap. Idempotent per local day.
 * Backed by [SeekPrefs] (epoch-day Long) rather than SwiftData.
 */
object StreakManager {
    private val MILESTONES = listOf(7, 30, 90, 365)

    /** Records today's activity and returns the resulting streak count. */
    suspend fun recordActivity(prefs: SeekPrefs): Int {
        val today = LocalDate.now().toEpochDay()
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
}
