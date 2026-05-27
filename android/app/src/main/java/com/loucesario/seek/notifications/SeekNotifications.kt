package com.loucesario.seek.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.loucesario.seek.MainActivity
import com.loucesario.seek.R

/**
 * Local notifications only (Phase A, like iOS). No APNs/FCM — daily verse +
 * streak nudge fire on-device via AlarmManager. APNs-style server push (verse
 * text in the body) is a later phase.
 */
object SeekNotifications {
    const val CHANNEL_ID = "seek_reminders"
    const val NOTIF_DAILY_VERSE = 1001
    const val NOTIF_STREAK = 1002

    fun ensureChannel(context: Context) {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Daily reminders",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply { description = "Daily verse and streak reminders" }
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    fun showDailyVerse(context: Context) =
        post(context, NOTIF_DAILY_VERSE, "Your Daily Verse", "Start your day with God's word. Tap to see today's verse.")

    fun showStreakNudge(context: Context) =
        post(context, NOTIF_STREAK, "Keep your streak going", "A quiet moment with Scripture is waiting for you.")

    private fun post(context: Context, id: Int, title: String, body: String) {
        ensureChannel(context)
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = PendingIntent.getActivity(
            context, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notif = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(pending)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(id, notif)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS not granted — silently skip.
        }
    }
}
