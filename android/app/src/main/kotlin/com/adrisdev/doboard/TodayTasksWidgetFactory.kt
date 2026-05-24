package com.adrisdev.doboard

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

// ─── Modelo de tarea para el widget ──────────────────────────────────────────

private data class TodayTaskItem(
    val id: String,
    val title: String,
    val isDone: Boolean,
    val isFrog: Boolean,
    val priority: Int,
)

// ─── Factory ─────────────────────────────────────────────────────────────────

class TodayTasksWidgetFactory(
    private val context: Context,
    @Suppress("UNUSED_PARAMETER") intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {

    // Solo mostramos tareas pendientes — las completadas desaparecen del widget
    private var tasks: List<TodayTaskItem> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = HomeWidgetPlugin.getData(context)
        val json  = prefs.getString(TodayTasksWidgetProvider.KEY_TASKS_JSON, null) ?: return
        // Filtramos directamente al cargar: solo las no completadas
        tasks = parseTasks(json).filter { !it.isDone }
    }

    override fun onDestroy() {}

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position >= tasks.size) return loadingView()

        val task = tasks[position]
        val rv   = RemoteViews(context.packageName, R.layout.widget_today_task_item)

        // ── Título ────────────────────────────────────────────────────────────
        rv.setTextViewText(R.id.task_title, task.title)
        rv.setFloat(R.id.task_title, "setAlpha", 1.0f)

        // ── Checkbox (siempre sin marcar, ya que filtramos las hechas) ────────
        rv.setTextViewText(R.id.task_check, "")
        rv.setInt(R.id.task_check, "setBackgroundResource", R.drawable.widget_check_undone)

        // ── Icono frog ────────────────────────────────────────────────────────
        rv.setTextViewText(R.id.task_frog, if (task.isFrog) "🐸" else "")

        // ── Fill-in intent: al pulsar la fila se marca como completada ────────
        val uri = Uri.parse(
            "doboard://widget/toggle_today" +
                "?taskId=${Uri.encode(task.id)}" +
                "&isDone=true",
        )
        val fillIntent = Intent().apply { data = uri }
        rv.setOnClickFillInIntent(R.id.task_item_root, fillIntent)

        return rv
    }

    override fun getLoadingView(): RemoteViews = loadingView()

    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private fun loadingView(): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_today_task_item)

    private fun parseTasks(json: String): List<TodayTaskItem> = try {
        val arr = JSONArray(json)
        (0 until arr.length()).map { i ->
            val obj = arr.getJSONObject(i)
            TodayTaskItem(
                id       = obj.getString("id"),
                title    = obj.getString("title"),
                isDone   = obj.getBoolean("isDone"),
                isFrog   = obj.optBoolean("isFrog", false),
                priority = obj.optInt("priority", 0),
            )
        }
    } catch (_: Exception) {
        emptyList()
    }
}
