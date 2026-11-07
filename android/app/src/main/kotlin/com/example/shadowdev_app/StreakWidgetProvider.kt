package com.example.shadowdev_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class StreakWidgetProvider : HomeWidgetProvider() {
    companion object {
        private val refreshUri = Uri.parse("shadowdev://refresh")
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val streakDays = widgetData.getInt("streak_count", 0).coerceAtLeast(0)
        val systemMessage =
            widgetData.getString("system_message", "النظام مستيقظ") ?: "النظام مستيقظ"
        val currentWeekday = widgetData.getInt("weekday_index", -1)
        val dayViewIds = intArrayOf(
            R.id.day_saturday,
            R.id.day_sunday,
            R.id.day_monday,
            R.id.day_tuesday,
            R.id.day_wednesday,
            R.id.day_thursday,
            R.id.day_friday,
        )
        val dayLabels = arrayOf("س", "ح", "ن", "ث", "ر", "خ", "ج")

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.streak_widget).apply {
                setTextViewText(R.id.streak_count, "🔥 $streakDays يوم")
                setTextViewText(R.id.system_message, systemMessage)
                setOnClickPendingIntent(
                    R.id.widget_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                setOnClickPendingIntent(
                    R.id.widget_refresh,
                    HomeWidgetBackgroundIntent.getBroadcast(context, refreshUri),
                )

                dayViewIds.forEachIndexed { index, viewId ->
                    setTextViewText(viewId, dayLabels[index])
                    setTextColor(
                        viewId,
                        context.resources.getColor(
                            if (index == currentWeekday) {
                                R.color.widget_day_active
                            } else {
                                R.color.widget_day_inactive
                            },
                        ),
                    )
                    setInt(
                        viewId,
                        "setBackgroundResource",
                        if (index == currentWeekday) {
                            R.drawable.widget_day_active
                        } else {
                            R.drawable.widget_day_default
                        },
                    )
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
