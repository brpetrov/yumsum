package com.bpetrov.yumsum

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Draws the mini log bar. The field opens the app with leanstreak://log/text
 * (box focused, keyboard up) and the mic with leanstreak://log/voice; the
 * Dart side turns each into a launch action.
 */
class LogWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val type = launch(context, "leanstreak://log/text")
        val speak = launch(context, "leanstreak://log/voice")
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.log_widget)
            views.setOnClickPendingIntent(R.id.log_widget_type, type)
            views.setOnClickPendingIntent(R.id.log_widget_mic, speak)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun launch(context: Context, uri: String): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse(uri),
        )
}
