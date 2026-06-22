package com.loucesario.seek.ui.home

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.loucesario.seek.data.SeekPrefs
import com.loucesario.seek.data.StreakManager
import com.loucesario.seek.data.remote.SeekApi
import com.loucesario.seek.data.remote.dto.DailyVerseDto
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

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

    init { refresh() }

    fun refresh() {
        viewModelScope.launch {
            _state.value = DailyVerseState.Loading
            _state.value = try {
                DailyVerseState.Loaded(SeekApi.dailyVerse())
            } catch (t: Throwable) {
                DailyVerseState.Error(FALLBACK)
            }
        }
    }

    /** Record today's activity (opening Home), updating the streak. Auth-only. */
    fun recordActivity() {
        viewModelScope.launch { StreakManager.recordActivity(prefs) }
    }
}
