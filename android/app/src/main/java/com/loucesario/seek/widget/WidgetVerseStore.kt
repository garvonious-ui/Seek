package com.loucesario.seek.widget

import android.content.Context
import org.json.JSONArray
import java.time.LocalDate

/**
 * Verse source for the home-screen widget. Mirrors the iOS `WidgetVerseProvider`
 * hybrid strategy:
 *  - the app writes the verse it just fetched into a synchronous SharedPreferences
 *    file (so the widget shows exactly what the app shows), stamped with the day
 *    it belongs to;
 *  - if there's no app-written verse for today, fall back to a deterministic
 *    by-date pick from the bundled `assets/daily_verses.json` pool, so a fresh
 *    install or an app the user hasn't opened still shows a fresh verse daily
 *    with zero network.
 *
 * SharedPreferences (not DataStore) because widget update callbacks run on the
 * main thread and need a synchronous read.
 */
object WidgetVerseStore {
    private const val PREFS = "seek_widget_prefs"
    private const val KEY_REF = "verse_ref"
    private const val KEY_TEXT = "verse_text"
    private const val KEY_THEME = "verse_theme"
    private const val KEY_DAY = "verse_epoch_day"

    data class Verse(val reference: String, val text: String, val theme: String)

    val FALLBACK = Verse(
        reference = "Psalm 46:1",
        text = "God is our refuge and strength, always ready to help in times of trouble.",
        theme = "strength",
    )

    /** Called by the app after a successful daily-verse fetch. */
    fun save(context: Context, reference: String, text: String, theme: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_REF, reference)
            .putString(KEY_TEXT, text)
            .putString(KEY_THEME, theme)
            .putLong(KEY_DAY, LocalDate.now().toEpochDay())
            .apply()
    }

    /** The verse to render right now: app-written if it's today's, else fallback. */
    fun resolved(context: Context): Verse {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val savedDay = prefs.getLong(KEY_DAY, -1L)
        val ref = prefs.getString(KEY_REF, null)
        val text = prefs.getString(KEY_TEXT, null)
        if (savedDay == LocalDate.now().toEpochDay() && ref != null && text != null) {
            return Verse(ref, text, prefs.getString(KEY_THEME, "") ?: "")
        }
        return deterministic(context)
    }

    // Bundled pool, parsed once and cached in memory.
    @Volatile private var poolCache: List<Verse>? = null

    private fun pool(context: Context): List<Verse> {
        poolCache?.let { return it }
        val parsed = try {
            val json = context.assets.open("daily_verses.json")
                .bufferedReader().use { it.readText() }
            val arr = JSONArray(json)
            buildList {
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    add(
                        Verse(
                            reference = o.getString("reference"),
                            text = o.getString("text"),
                            theme = o.optString("theme", ""),
                        )
                    )
                }
            }
        } catch (t: Throwable) {
            listOf(FALLBACK)
        }
        val result = parsed.ifEmpty { listOf(FALLBACK) }
        poolCache = result
        return result
    }

    private fun deterministic(context: Context): Verse {
        val pool = pool(context)
        if (pool.isEmpty()) return FALLBACK
        val day = LocalDate.now().toEpochDay()
        val index = ((day % pool.size) + pool.size) % pool.size
        return pool[index.toInt()]
    }
}
