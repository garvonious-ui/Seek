package com.loucesario.seek.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import com.loucesario.seek.MainActivity
import com.loucesario.seek.R
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

/**
 * Home-screen Verse of the Day widget. (Android removed lock-screen/keyguard
 * widgets in 5.0, so the iOS lock-screen families have no Android counterpart —
 * this is the platform-equivalent home widget.)
 *
 * Renders [WidgetVerseStore.resolved] and reschedules a midnight refresh so the
 * verse rolls over daily even if the app is never opened.
 */
class DailyVerseWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { id -> renderWidget(context, manager, id) }
        scheduleMidnightRefresh(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_DAILY_REFRESH) {
            refresh(context)
            scheduleMidnightRefresh(context)
        }
    }

    override fun onEnabled(context: Context) {
        scheduleMidnightRefresh(context)
    }

    override fun onDisabled(context: Context) {
        alarmManager(context).cancel(refreshPendingIntent(context))
    }

    companion object {
        private const val ACTION_DAILY_REFRESH = "com.loucesario.seek.widget.DAILY_REFRESH"

        /** Re-render every placed instance. Safe to call from anywhere (e.g. the app). */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, DailyVerseWidget::class.java))
            ids.forEach { id -> renderWidget(context, manager, id) }
        }

        private fun renderWidget(context: Context, manager: AppWidgetManager, id: Int) {
            val verse = WidgetVerseStore.resolved(context)
            val views = RemoteViews(context.packageName, R.layout.widget_daily_verse).apply {
                setTextViewText(R.id.widget_theme, verse.theme.replaceFirstChar { it.uppercase() })
                setTextViewText(R.id.widget_verse_text, "“${verse.text}”")
                setTextViewText(R.id.widget_reference, "— ${verse.reference}")
                setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent(context))
            }
            manager.updateAppWidget(id, views)
        }

        private fun openAppPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("seek://dailyverse")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            return PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun alarmManager(context: Context) =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        private fun refreshPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, DailyVerseWidget::class.java).apply {
                action = ACTION_DAILY_REFRESH
            }
            return PendingIntent.getBroadcast(
                context, 1, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        /** Fire once just after the next local midnight; re-armed on each fire. */
        private fun scheduleMidnightRefresh(context: Context) {
            val nextMidnight = LocalDate.now().plusDays(1)
                .atTime(LocalTime.of(0, 0, 5))
                .atZone(ZoneId.systemDefault())
                .toInstant()
                .toEpochMilli()
            // Inexact-while-idle: we don't need second precision, just "early next day."
            alarmManager(context).setAndAllowWhileIdle(
                AlarmManager.RTC, nextMidnight, refreshPendingIntent(context),
            )
        }
    }
}
