package com.adrisdev.doboard

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetProvider

class TodayTasksWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val taskCount = widgetData.getInt(KEY_TASK_COUNT, 0)
        val feedback  = resolveFeedback(widgetData)

        appWidgetIds.forEach { widgetId ->
            val views = buildRemoteViews(context, widgetId, taskCount, feedback)
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        // CLAVE: fuerza que TodayTasksWidgetFactory.onDataSetChanged() se ejecute
        // y re-lea el JSON de SharedPreferences. Sin esto el ListView nunca se actualiza.
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.today_tasks_list)
    }

    private fun buildRemoteViews(
        context: Context,
        widgetId: Int,
        taskCount: Int,
        feedback: String?,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_today_tasks)

        // ── Feedback temporal ────────────────────────────────────────────────
        if (feedback.isNullOrBlank()) {
            views.setViewVisibility(R.id.today_feedback, View.GONE)
        } else {
            views.setViewVisibility(R.id.today_feedback, View.VISIBLE)
            views.setTextViewText(R.id.today_feedback, feedback)
        }

        // ── Lista vs. estado vacío ───────────────────────────────────────────
        if (taskCount == 0) {
            views.setViewVisibility(R.id.today_tasks_list, View.GONE)
            views.setViewVisibility(R.id.today_empty_view, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.today_tasks_list, View.VISIBLE)
            views.setViewVisibility(R.id.today_empty_view, View.GONE)
        }

        // ── Adapter del ListView ─────────────────────────────────────────────
        // Cada widgetId necesita un URI único para que Android gestione
        // cada instancia del widget como un RemoteViewsFactory independiente.
        val serviceIntent = Intent(context, TodayTasksWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        views.setRemoteAdapter(R.id.today_tasks_list, serviceIntent)

        // ── Pending intent template para clicks en ítems (toggle done) ───────
        val templateIntent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
            action = "es.antonborri.home_widget.action.BACKGROUND"
        }
        val templatePendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_TOGGLE,
            templateIntent,
            pendingIntentFlags(),
        )
        views.setPendingIntentTemplate(R.id.today_tasks_list, templatePendingIntent)

        // ── Botón «+» → abre diálogo para añadir tarea urgente ──────────────
        val addIntent = Intent(context, TodayTasksWidgetActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val addPendingIntent = PendingIntent.getActivity(
            context,
            REQUEST_ADD,
            addIntent,
            pendingIntentFlags(),
        )
        views.setOnClickPendingIntent(R.id.today_btn_add, addPendingIntent)

        // ── Título «🐸 Hoy» → abre la app directamente ──────────────────────
        val openAppIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }
        if (openAppIntent != null) {
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                REQUEST_OPEN_APP_TODAY,
                openAppIntent,
                pendingIntentFlags(),
            )
            views.setOnClickPendingIntent(R.id.today_widget_title, openAppPendingIntent)
        }

        return views
    }

    private fun resolveFeedback(widgetData: SharedPreferences): String? {
        val text = widgetData.getString(KEY_LAST_FEEDBACK, null)
        if (text.isNullOrBlank()) return null
        val at = widgetData.getLong(KEY_LAST_FEEDBACK_AT, 0L)
        if (at == 0L) return text
        return if (System.currentTimeMillis() - at < FEEDBACK_VISIBLE_MS) text else null
    }

    private fun pendingIntentFlags(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

    companion object {
        const val KEY_TASKS_JSON       = "today_tasks_json"
        const val KEY_TASK_COUNT       = "today_tasks_count"
        const val KEY_LAST_FEEDBACK    = "today_last_feedback"
        const val KEY_LAST_FEEDBACK_AT = "today_last_feedback_at"

        private const val FEEDBACK_VISIBLE_MS    = 2_500L
        private const val REQUEST_TOGGLE         = 21
        private const val REQUEST_ADD            = 22
        private const val REQUEST_OPEN_APP_TODAY = 23
    }
}
