package com.loucesario.seek

import android.app.Application
import com.loucesario.seek.data.ConnectivityObserver
import com.loucesario.seek.data.SessionRepository
import com.loucesario.seek.data.local.SeekDatabase
import com.loucesario.seek.notifications.SeekNotifications

/**
 * App-wide singletons. Lightweight manual DI for now (no Hilt yet) — mirrors the
 * pragmatic iOS approach of shared service objects.
 */
class SeekApplication : Application() {
    val database: SeekDatabase by lazy { SeekDatabase.get(this) }
    val sessionRepository: SessionRepository by lazy { SessionRepository(this) }
    val connectivity: ConnectivityObserver by lazy { ConnectivityObserver(this) }

    companion object {
        lateinit var instance: SeekApplication
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        SeekNotifications.ensureChannel(this)
    }
}
