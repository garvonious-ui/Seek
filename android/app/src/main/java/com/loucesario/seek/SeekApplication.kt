package com.loucesario.seek

import android.app.Application
import com.loucesario.seek.data.SessionRepository
import com.loucesario.seek.data.local.SeekDatabase

/**
 * App-wide singletons. Lightweight manual DI for now (no Hilt yet) — mirrors the
 * pragmatic iOS approach of shared service objects.
 */
class SeekApplication : Application() {
    val database: SeekDatabase by lazy { SeekDatabase.get(this) }
    val sessionRepository: SessionRepository by lazy { SessionRepository(this) }

    companion object {
        lateinit var instance: SeekApplication
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }
}
