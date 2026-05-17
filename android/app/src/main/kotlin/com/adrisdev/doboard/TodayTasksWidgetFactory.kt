package com.adrisdev.doboard

import android.content.Context
import android.content.Intent
import android.graphics.Paint
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

    private var tasks: List<TodayTaskItem> = emptyList()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = HomeWidgetPlugin.getData(context)
        val json  = prefs.getString(TodayTasksWidgetProvider.KEY_TASKS_JSON, null) ?: return
        tasks = parseTasks(json)
    }

    override fun onDestroy() {}

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position >= tasks.size) return loadingView()

        val task = tasks[position]
        val rv   = RemoteViews(context.packageName, R.layout.widget_today_task_item)

        // ── Título (tachado + semitransparente si completada) ────────────────
        rv.setTextViewText(R.id.task_title, task.title)

        val paintFlags = if (task.isDone) {
            Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG
        } else {
            Paint.ANTI_ALIAS_FLAG
        }
        rv.setInt(R.id.task_title, "setPaintFlags", paintFlags)

        // setAlpha recibe Float (0.0–1.0), NO Int — de lo contrario Android
        // lanza una excepción y muestra «Cargando…» en cada ítem.
        rv.setFloat(R.id.task_title, "setAlpha", if (task.isDone) 0.45f else 1.0f)

        // ── Checkbox ─────────────────────────────────────────────────────────
        if (task.isDone) {
            rv.setTextViewText(R.id.task_check, "✓")
            rv.setInt(R.id.task_check, "setBackgroundResource", R.drawable.widget_check_done)
        } else {
            rv.setTextViewText(R.id.task_check, "")
            rv.setInt(R.id.task_check, "setBackgroundResource", R.drawable.widget_check_undone)
        }

        // ── Icono frog ───────────────────────────────────────────────────────
        rv.setTextViewText(R.id.task_frog, if (task.isFrog) "🐸" else "")

        // ── Fill-in intent para toggle (se combina con el template) ──────────
        val uri = Uri.parse(
            "doboard://widget/toggle_today" +
                "?taskId=${Uri.encode(task.id)}" +
                "&isDone=${!task.isDone}",
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
