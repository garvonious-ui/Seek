package com.loucesario.seek.data

import android.content.Context
import android.icu.text.DateFormat
import com.loucesario.seek.SeekApplication
import com.loucesario.seek.data.remote.SeekJson
import com.loucesario.seek.data.remote.dto.ChatResponse
import com.loucesario.seek.widget.WidgetVerseStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.temporal.TemporalAdjusters
import java.util.Date
import java.util.Locale

/**
 * One week's recap (Mon–Sun, local calendar) for the Weekly Summary card.
 * Built entirely from on-device data — nothing new is sent to the server.
 * Mirrors the iOS WeeklySummary.
 */
data class WeeklySummary(
    val weekStart: LocalDate,
    /** Mon…Sun. */
    val activeDays: List<Boolean>,
    val versesExplored: Int,
    val prayersSaved: Int,
    val cardsMade: Int,
    /** Up to three, most-mentioned first. */
    val themes: List<String>,
    val verseText: String,
    val verseReference: String,
    val streak: Int,
    val longestStreak: Int,
) {
    val id: String get() = StreakManager.dayKey(weekStart)
    val daysActive: Int get() = activeDays.count { it }
    /** A light week gets encouragement instead of a streak brag. */
    val isQuiet: Boolean get() = daysActive <= 2

    /** "Oct 5 – 11", or "Sep 28 – Oct 4" across months (localized like iOS's date templates). */
    val dateRange: String
        get() {
            val end = weekStart.plusDays(6)
            val month = DateFormat.getInstanceForSkeleton("MMMd", Locale.getDefault())
            val day = DateFormat.getInstanceForSkeleton("d", Locale.getDefault())
            val sameMonth = weekStart.year == end.year && weekStart.month == end.month
            val endText = if (sameMonth) day.format(end.toDate()) else month.format(end.toDate())
            return "${month.format(weekStart.toDate())} – $endText"
        }

    private fun LocalDate.toDate(): Date = Date.from(atStartOfDay(ZoneId.systemDefault()).toInstant())
}

object WeeklySummaryBuilder {
    private const val FALLBACK_TEXT = "God is our refuge and strength, a very present help in trouble."
    private const val FALLBACK_REFERENCE = "Psalm 46:1"

    /** Weeks run Monday–Sunday regardless of locale, to match the card's M…S row. */
    fun weekStart(containing: LocalDate): LocalDate =
        containing.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))

    /**
     * The week the Home tile offers right now: this week from Sunday noon,
     * last week on Monday and Tuesday, otherwise none.
     */
    fun recapWeekStart(now: LocalDateTime = LocalDateTime.now()): LocalDate? = when (now.dayOfWeek) {
        DayOfWeek.SUNDAY -> if (now.hour >= 12) weekStart(now.toLocalDate()) else null
        DayOfWeek.MONDAY, DayOfWeek.TUESDAY -> weekStart(now.toLocalDate()).minusWeeks(1)
        else -> null
    }

    suspend fun build(context: Context, weekStart: LocalDate): WeeklySummary {
        val db = (context.applicationContext as SeekApplication).database
        val prefs = SeekPrefs(context)
        val zone = ZoneId.systemDefault()
        val start = weekStart.atStartOfDay(zone).toInstant().toEpochMilli()
        val end = weekStart.plusDays(7).atStartOfDay(zone).toInstant().toEpochMilli()

        val messages = db.chatDao().messagesBetween(start, end)
        val favorites = db.favoriteVerseDao().savedBetween(start, end) // newest first
        val prayers = db.savedPrayerDao().savedBetween(start, end)
        val cards = db.savedCardDao().createdBetween(start, end)
        val streak = prefs.streakSnapshot()
        val activeLog = StreakManager.activeDayKeys(prefs)

        return withContext(Dispatchers.Default) {
            val userMessages = messages.filter { it.role == "user" }
            // Assistant rows hold the full ChatResponse JSON (ChatViewModel.renderResponse).
            val responses = messages
                .filter { it.role == "assistant" }
                .mapNotNull { runCatching { SeekJson.decodeFromString(ChatResponse.serializer(), it.content) }.getOrNull() }

            // Days in the Word: the active-day log, plus timestamps on what the
            // user did (covers weeks from before the log existed).
            val stamps = userMessages.map { it.timestamp } + favorites.map { it.savedAt } +
                prayers.map { it.savedAt } + cards.map { it.createdAt }
            val activeKeys = activeLog + stamps.map { StreakManager.dayKey(it) }
            val activeDays = (0L until 7L).map { StreakManager.dayKey(weekStart.plusDays(it)) in activeKeys }

            // The verse that carried the week: the latest one they favorited,
            // else the latest one Seek gave them, else the daily verse.
            val featured = favorites.firstOrNull()?.let { it.text to it.reference }
                ?: responses.lastOrNull { it.verses.isNotEmpty() }?.verses?.first()?.let { it.text to it.reference }
                ?: WidgetVerseStore.lastSaved(context)?.let { it.text to it.reference }
                ?: (FALLBACK_TEXT to FALLBACK_REFERENCE)

            WeeklySummary(
                weekStart = weekStart,
                activeDays = activeDays,
                versesExplored = responses.sumOf { it.verses.size },
                prayersSaved = prayers.size,
                cardsMade = cards.size,
                themes = themes(userMessages.map { it.content }),
                verseText = featured.first,
                verseReference = featured.second,
                streak = streak.count,
                longestStreak = streak.longest,
            )
        }
    }

    // Themes — plain keyword matching on the user's own messages, on-device.
    // The raw messages never appear on the card — only these theme names do.
    private val THEME_KEYWORDS: List<Pair<String, List<String>>> = listOf(
        "Anxiety" to listOf("anxious", "anxiety", "worry", "worried", "stress", "overwhelm", "panic"),
        "Fear" to listOf("fear", "afraid", "scared", "terrified"),
        "Grief" to listOf("grief", "grieving", "mourning", "passed away", "funeral", "lost my"),
        "Loneliness" to listOf("lonely", "loneliness", "alone", "isolated"),
        "Gratitude" to listOf("gratitude", "grateful", "thankful", "blessed"),
        "Joy" to listOf("joy", "happy", "celebrat"),
        "Rest" to listOf("weariness", "weary", "tired", "exhausted", "burned out", "burnt out", "rest"),
        "Doubt" to listOf("doubt", "unsure", "questioning"),
        "Anger" to listOf("anger", "angry", "furious", "resent"),
        "Temptation" to listOf("temptation", "tempted", "addiction"),
        "Hope" to listOf("hope", "hopeless", "despair"),
        "Forgiveness" to listOf("forgive", "forgiveness", "guilt", "guilty", "shame"),
        "Healing" to listOf("healing", "sick", "illness", "surgery", "diagnos", "pain"),
        "Guidance" to listOf("guidance", "decision", "direction", "purpose", "what should i"),
        "Relationships" to listOf("marriage", "husband", "wife", "relationship", "family", "friendship"),
    )

    /** Up to three theme names, most-mentioned first; ties keep the table's order. */
    fun themes(texts: List<String>): List<String> {
        val counts = mutableMapOf<String, Int>()
        for (text in texts) {
            val lower = text.lowercase()
            for ((name, words) in THEME_KEYWORDS) {
                if (words.any { lower.contains(it) }) counts[name] = (counts[name] ?: 0) + 1
            }
        }
        val order = THEME_KEYWORDS.mapIndexed { index, (name, _) -> name to index }.toMap()
        return counts.entries
            .sortedWith(compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { order.getValue(it.key) })
            .take(3)
            .map { it.key }
    }
}
