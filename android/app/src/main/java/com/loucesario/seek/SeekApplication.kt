package com.loucesario.seek

import android.app.Application
import com.loucesario.seek.data.ConnectivityObserver
import com.loucesario.seek.data.AuthState
import com.loucesario.seek.data.SessionRepository
import com.loucesario.seek.data.SyncRepository
import com.loucesario.seek.data.local.SeekDatabase
import com.loucesario.seek.notifications.SeekNotifications
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

/**
 * App-wide singletons. Lightweight manual DI for now (no Hilt yet) — mirrors the
 * pragmatic iOS approach of shared service objects.
 */
class SeekApplication : Application() {
    val database: SeekDatabase by lazy { SeekDatabase.get(this) }
    val sessionRepository: SessionRepository by lazy { SessionRepository(this) }
    val connectivity: ConnectivityObserver by lazy { ConnectivityObserver(this) }
    val sync: SyncRepository by lazy { SyncRepository(this, database) }
    private val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    companion object {
        lateinit var instance: SeekApplication
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        SeekNotifications.ensureChannel(this)
        // Cloud sync: restore/back up the library as soon as an account signs in
        // (also covers a cold start with a saved session).
        appScope.launch {
            sessionRepository.session.map { it.authState }.distinctUntilChanged().collect { state ->
                if (state == AuthState.AUTHENTICATED) sync.syncNow()
            }
        }
    }
}
