package com.adrisdev.doboard

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class AddTaskWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_SELECT_BOARD) {
            val boardId = intent.getStringExtra(EXTRA_BOARD_ID) ?: return
            saveSelectedBoard(context, boardId)
            clearFeedback(context)
            refreshAllWidgets(context)
            return
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val selectedBoard =
            widgetData.getString(PREF_SELECTED_BOARD, BOARD_RAPIDAS) ?: BOARD_RAPIDAS
        val feedback = resolveFeedback(context, widgetData)

        appWidgetIds.forEach { widgetId ->
            val views = buildRemoteViews(context, selectedBoard, feedback)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun buildRemoteViews(
        context: Context,
        selectedBoard: String,
        feedback: String?,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_add_task)

        if (feedback.isNullOrBlank()) {
            views.setViewVisibility(R.id.widget_feedback, android.view.View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_feedback, android.view.View.VISIBLE)
            views.setTextViewText(R.id.widget_feedback, feedback)
        }

        styleChip(context, views, R.id.widget_chip_rapidas, selectedBoard == BOARD_RAPIDAS, CHIP_RAPIDAS)
        styleChip(context, views, R.id.widget_chip_medias, selectedBoard == BOARD_MEDIAS, CHIP_MEDIAS)
        styleChip(context, views, R.id.widget_chip_largas, selectedBoard == BOARD_LARGAS, CHIP_LARGAS)

        val addPendingIntent = buildAddPendingIntent(context, selectedBoard)
        views.setOnClickPendingIntent(R.id.widget_btn_add, addPendingIntent)
        views.setOnClickPendingIntent(R.id.widget_input_row, addPendingIntent)
        views.setOnClickPendingIntent(R.id.widget_input_hint, addPendingIntent)

        views.setOnClickPendingIntent(
            R.id.widget_chip_rapidas,
            buildSelectPendingIntent(context, BOARD_RAPIDAS, REQUEST_CHIP_RAPIDAS),
        )
        views.setOnClickPendingIntent(
            R.id.widget_chip_medias,
            buildSelectPendingIntent(context, BOARD_MEDIAS, REQUEST_CHIP_MEDIAS),
        )
        views.setOnClickPendingIntent(
            R.id.widget_chip_largas,
            buildSelectPendingIntent(context, BOARD_LARGAS, REQUEST_CHIP_LARGAS),
        )

        // ── Título «Doboard» → abre la app directamente ─────────────────────
        val openAppIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }
        if (openAppIntent != null) {
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                REQUEST_OPEN_APP,
                openAppIntent,
                pendingIntentFlags(),
            )
            views.setOnClickPendingIntent(R.id.widget_title, openAppPendingIntent)
        }

        return views
    }

    private fun styleChip(
        context: Context,
        views: RemoteViews,
        viewId: Int,
        selected: Boolean,
        chip: ChipStyle,
    ) {
        views.setInt(viewId, "setBackgroundResource", chip.background(selected))
        val textColor = if (selected) {
            Color.WHITE
        } else {
            context.getColor(chip.unselectedTextColor)
        }
        views.setTextColor(viewId, textColor)
    }

    private fun buildSelectPendingIntent(
        context: Context,
        boardId: String,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, AddTaskWidgetProvider::class.java).apply {
            action = ACTION_SELECT_BOARD
            putExtra(EXTRA_BOARD_ID, boardId)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            pendingIntentFlags(),
        )
    }

    private fun buildAddPendingIntent(context: Context, boardId: String): PendingIntent {
        val intent = Intent(context, AddTaskWidgetActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AddTaskWidgetActivity.EXTRA_BOARD_ID, boardId)
        }
        return PendingIntent.getActivity(
            context,
            REQUEST_ADD,
            intent,
            pendingIntentFlags(),
        )
    }

    private fun pendingIntentFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }

    private fun saveSelectedBoard(context: Context, boardId: String) {
        HomeWidgetPlugin.getData(context).edit()
            .putString(PREF_SELECTED_BOARD, boardId)
            .apply()
    }

    private fun resolveFeedback(
        context: Context,
        widgetData: SharedPreferences,
    ): String? {
        val text = widgetData.getString(PREF_LAST_FEEDBACK, null)
        if (text.isNullOrBlank()) return null

        val at = widgetData.getLong(PREF_LAST_FEEDBACK_AT, 0L)
        if (at == 0L) return text

        val elapsed = System.currentTimeMillis() - at
        return if (elapsed < FEEDBACK_VISIBLE_MS) {
            text
        } else {
            clearFeedback(context)
            null
        }
    }

    private fun clearFeedback(context: Context) {
        HomeWidgetPlugin.getData(context).edit()
            .remove(PREF_LAST_FEEDBACK)
            .remove(PREF_LAST_FEEDBACK_AT)
            .apply()
    }

    private fun refreshAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, AddTaskWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(component)
        onUpdate(context, manager, ids, HomeWidgetPlugin.getData(context))
    }

    private data class ChipStyle(
        val selectedBg: Int,
        val unselectedTextColor: Int,
    ) {
        fun background(selected: Boolean): Int =
            if (selected) selectedBg else R.drawable.widget_chip_unselected
    }

    companion object {
        const val PREF_SELECTED_BOARD  = "selected_board_id"
        const val PREF_LAST_FEEDBACK   = "last_feedback"
        const val PREF_LAST_FEEDBACK_AT = "last_feedback_at"
        private const val FEEDBACK_VISIBLE_MS = 2_500L

        const val BOARD_RAPIDAS = "board-rapidas"
        const val BOARD_MEDIAS  = "board-calma"
        const val BOARD_LARGAS  = "board-prisa"

        private const val ACTION_SELECT_BOARD  = "com.adrisdev.doboard.WIDGET_SELECT_BOARD"
        private const val EXTRA_BOARD_ID       = "board_id"

        private const val REQUEST_CHIP_RAPIDAS = 10
        private const val REQUEST_CHIP_MEDIAS  = 11
        private const val REQUEST_CHIP_LARGAS  = 12
        private const val REQUEST_ADD          = 13
        private const val REQUEST_OPEN_APP     = 14   // nuevo — tap en título

        private val CHIP_RAPIDAS = ChipStyle(
            selectedBg = R.drawable.widget_chip_rapidas_selected,
            unselectedTextColor = R.color.widget_chip_unselected_text,
        )
        private val CHIP_MEDIAS = ChipStyle(
            selectedBg = R.drawable.widget_chip_medias_selected,
            unselectedTextColor = R.color.widget_chip_unselected_text,
        )
        private val CHIP_LARGAS = ChipStyle(
            selectedBg = R.drawable.widget_chip_largas_selected,
            unselectedTextColor = R.color.widget_chip_unselected_text,
        )
    }
}
