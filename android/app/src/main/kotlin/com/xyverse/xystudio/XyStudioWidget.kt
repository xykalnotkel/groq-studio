package com.xyverse.xystudio

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

/**
 * Widget layar beranda XyStudio AI.
 *
 * Menampilkan pintasan ke empat mode (Judul, Caption, Artikel, Ide) yang
 * membuka aplikasi langsung pada mode tersebut.
 */
class XyStudioWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_xystudio)
        bindButton(context, views, R.id.widget_btn_judul, "judul", 1)
        bindButton(context, views, R.id.widget_btn_caption, "caption", 2)
        bindButton(context, views, R.id.widget_btn_artikel, "artikel", 3)
        bindButton(context, views, R.id.widget_btn_ide, "ide", 4)
        bindButton(context, views, R.id.widget_root, null, 0)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun bindButton(
        context: Context,
        views: RemoteViews,
        viewId: Int,
        mode: String?,
        requestCode: Int,
    ) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (mode != null) putExtra(MainActivity.EXTRA_MODE, mode)
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or PendingIntent.FLAG_IMMUTABLE
        }
        val pending = PendingIntent.getActivity(context, requestCode, intent, flags)
        views.setOnClickPendingIntent(viewId, pending)
    }
}
