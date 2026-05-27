package com.loucesario.seek.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Fired by AlarmManager — posts the appropriate reminder. */
class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.getStringExtra(NotificationScheduler.EXTRA_TYPE)) {
            NotificationScheduler.TYPE_STREAK -> SeekNotifications.showStreakNudge(context)
            else -> SeekNotifications.showDailyVerse(context)
        }
    }
}
