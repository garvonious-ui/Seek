package com.loucesario.seek.notifications

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import java.util.Calendar

/**
 * Schedules daily reminders with `setInexactRepeating` — fires roughly at the
 * chosen local time every day, and needs NO exact-alarm permission (which
 * Android 13+ otherwise gates). A few minutes of drift is fine for a devotional
 * nudge.
 */
object NotificationScheduler {
    const val EXTRA_TYPE = "type"
    const val TYPE_VERSE = "verse"
    const val TYPE_STREAK = "streak"

    fun schedule(context: Context, type: String, hour: Int, minute: Int) {
        val am = context.getSystemService(AlarmManager::class.java)
        am.setInexactRepeating(
            AlarmManager.RTC_WAKEUP,
            nextTrigger(hour, minute),
            AlarmManager.INTERVAL_DAY,
            pendingIntent(context, type),
        )
    }

    fun cancel(context: Context, type: String) {
        context.getSystemService(AlarmManager::class.java).cancel(pendingIntent(context, type))
    }

    private fun pendingIntent(context: Context, type: String): PendingIntent {
        val intent = Intent(context, NotificationReceiver::class.java).putExtra(EXTRA_TYPE, type)
        val requestCode = if (type == TYPE_STREAK) 2 else 1
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun nextTrigger(hour: Int, minute: Int): Long {
        val now = Calendar.getInstance()
        val target = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            if (before(now)) add(Calendar.DAY_OF_YEAR, 1)
        }
        return target.timeInMillis
    }
}
