package com.loucesario.seek.ui.home

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.loucesario.seek.data.SeekPrefs
import com.loucesario.seek.data.StreakManager
import com.loucesario.seek.data.WeeklySummary
import com.loucesario.seek.data.WeeklySummaryBuilder
import com.loucesario.seek.data.remote.SeekApi
import com.loucesario.seek.data.remote.dto.DailyVerseDto
import com.loucesario.seek.widget.DailyVerseWidget
import com.loucesario.seek.widget.WidgetVerseStore
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalDate

sealed interface DailyVerseState {
    data object Loading : DailyVerseState
    data class Loaded(val verse: DailyVerseDto) : DailyVerseState
    data class Error(val cached: DailyVerseDto) : DailyVerseState
}

/** Evergreen fallback so the card is never empty (matches the iOS offline behavior). */
private val FALLBACK = DailyVerseDto(
    reference = "Psalm 46:1",
    text = "God is our refuge and strength, always ready to help in times of trouble.",
    theme = "strength",
)

class HomeViewModel(app: Application) : AndroidViewModel(app) {
    private val prefs = SeekPrefs(app)

    private val _state = MutableStateFlow<DailyVerseState>(DailyVerseState.Loading)
    val state: StateFlow<DailyVerseState> = _state.asStateFlow()

    /** Current streak count — drives the Home capsule. */
    val streak: StateFlow<Int> = prefs.streakCount
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    private val _recap = MutableStateFlow<WeeklySummary?>(null)
    /** The "Your week is ready" tile's week, when one is on offer (see [loadWeeklyRecap]). */
    val recap: StateFlow<WeeklySummary?> = _recap.asStateFlow()

    private val _presentedSummary = MutableStateFlow<WeeklySummary?>(null)
    /** The week open in the recap sheet, if any. */
    val presentedSummary: StateFlow<WeeklySummary?> = _presentedSummary.asStateFlow()

    init { refresh() }

    fun refresh() {
        viewModelScope.launch {
            _state.value = DailyVerseState.Loading
            _state.value = try {
                val verse = SeekApi.dailyVerse()
                // Mirror today's verse to the widget store and refresh any placed
                // widgets so the home-screen Verse of the Day matches the app.
                WidgetVerseStore.save(
                    getApplication(),
                    reference = verse.reference,
                    text = verse.text,
                    theme = verse.theme ?: "",
                )
                DailyVerseWidget.refresh(getApplication())
                DailyVerseState.Loaded(verse)
            } catch (t: Throwable) {
                DailyVerseState.Error(FALLBACK)
            }
        }
    }

    /** Record today's activity (opening Home), updating the streak, then offer the weekly recap. Auth-only. */
    fun recordActivity() {
        viewModelScope.launch {
            StreakManager.recordActivity(prefs)
            loadWeeklyRecap()
        }
    }

    /**
     * Offer the recap tile when it's recap time (Sunday noon – Tuesday), the
     * user hasn't dismissed this week's, and they showed up at least once.
     */
    private suspend fun loadWeeklyRecap() {
        val start = WeeklySummaryBuilder.recapWeekStart()
        if (start == null || StreakManager.dayKey(start) == prefs.dismissedRecapWeek()) {
            _recap.value = null
            return
        }
        val summary = WeeklySummaryBuilder.build(getApplication(), start)
        _recap.value = summary.takeIf { it.daysActive > 0 }
    }

    fun openRecap() {
        _presentedSummary.value = _recap.value
    }

    fun dismissRecap() {
        val recap = _recap.value ?: return
        _recap.value = null
        viewModelScope.launch { prefs.setDismissedRecapWeek(recap.id) }
    }

    /** Tapping the streak opens this week so far, any day. */
    fun openCurrentWeek() {
        viewModelScope.launch {
            _presentedSummary.value = WeeklySummaryBuilder.build(
                getApplication(),
                WeeklySummaryBuilder.weekStart(LocalDate.now()),
            )
        }
    }

    fun closeSummary() {
        _presentedSummary.value = null
    }
}
