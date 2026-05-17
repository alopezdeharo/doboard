package com.adrisdev.doboard

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

/**
 * Diálogo flotante para añadir una tarea urgente directamente al tablero «Hoy».
 * Se abre al pulsar el botón «+» del widget [TodayTasksWidgetProvider].
 */
class TodayTasksWidgetActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_today_tasks_widget)
        applyDialogSize()

        val input  = findViewById<EditText>(R.id.today_dialog_input)
        val submit = findViewById<TextView>(R.id.today_dialog_btn_submit)
        val cancel = findViewById<TextView>(R.id.today_dialog_btn_cancel)

        cancel.setOnClickListener { finish() }

        submit.setOnClickListener { submitTask(input) }

        input.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                submitTask(input)
                true
            } else {
                false
            }
        }

        // Mostrar teclado automáticamente
        input.post {
            input.requestFocus()
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            imm.showSoftInput(input, InputMethodManager.SHOW_IMPLICIT)
        }
    }

    private fun applyDialogSize() {
        window.setBackgroundDrawableResource(android.R.color.transparent)
        val percent = resources.getInteger(R.integer.widget_dialog_width_percent)
        val width   = resources.displayMetrics.widthPixels * percent / 100
        window.setLayout(width, WindowManager.LayoutParams.WRAP_CONTENT)
        window.setGravity(Gravity.CENTER)
        val params = window.attributes
        params.dimAmount = 0.6f
        window.attributes = params
    }

    private fun submitTask(input: EditText) {
        val title = input.text.toString().trim()
        if (title.isEmpty()) {
            input.error = getString(R.string.today_widget_hint)
            return
        }

        val uri = Uri.parse(
            "doboard://widget/add_today?title=${Uri.encode(title)}",
        )
        HomeWidgetBackgroundIntent.getBroadcast(this, uri).send()

        refreshWidget()
        finish()
    }

    private fun refreshWidget() {
        val manager   = AppWidgetManager.getInstance(this)
        val component = ComponentName(this, TodayTasksWidgetProvider::class.java)
        val ids       = manager.getAppWidgetIds(component)
        if (ids.isNotEmpty()) {
            val intent = Intent(this, TodayTasksWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            sendBroadcast(intent)
        }
    }
}
