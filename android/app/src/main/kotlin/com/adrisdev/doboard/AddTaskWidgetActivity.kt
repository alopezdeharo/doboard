package com.adrisdev.doboard

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Diálogo flotante centrado para añadir tareas desde el widget.
 */
class AddTaskWidgetActivity : Activity() {

    private var selectedBoardId: String = AddTaskWidgetProvider.BOARD_RAPIDAS

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        clearWidgetFeedback()
        setContentView(R.layout.activity_add_task_widget)
        applyDialogSize()

        selectedBoardId = intent.getStringExtra(EXTRA_BOARD_ID)
            ?: HomeWidgetPlugin.getData(this).getString(
                AddTaskWidgetProvider.PREF_SELECTED_BOARD,
                AddTaskWidgetProvider.BOARD_RAPIDAS,
            )
            ?: AddTaskWidgetProvider.BOARD_RAPIDAS

        val input = findViewById<EditText>(R.id.dialog_input)
        val chipRapidas = findViewById<TextView>(R.id.dialog_chip_rapidas)
        val chipMedias = findViewById<TextView>(R.id.dialog_chip_medias)
        val chipLargas = findViewById<TextView>(R.id.dialog_chip_largas)
        val submit = findViewById<TextView>(R.id.dialog_btn_submit)

        fun selectBoard(boardId: String) {
            selectedBoardId = boardId
            HomeWidgetPlugin.getData(this).edit()
                .putString(AddTaskWidgetProvider.PREF_SELECTED_BOARD, boardId)
                .apply()
            styleChip(chipRapidas, boardId == AddTaskWidgetProvider.BOARD_RAPIDAS, CHIP_RAPIDAS)
            styleChip(chipMedias, boardId == AddTaskWidgetProvider.BOARD_MEDIAS, CHIP_MEDIAS)
            styleChip(chipLargas, boardId == AddTaskWidgetProvider.BOARD_LARGAS, CHIP_LARGAS)
        }

        selectBoard(selectedBoardId)

        chipRapidas.setOnClickListener { selectBoard(AddTaskWidgetProvider.BOARD_RAPIDAS) }
        chipMedias.setOnClickListener { selectBoard(AddTaskWidgetProvider.BOARD_MEDIAS) }
        chipLargas.setOnClickListener { selectBoard(AddTaskWidgetProvider.BOARD_LARGAS) }

        submit.setOnClickListener { submitTask(input) }
        input.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                submitTask(input)
                true
            } else {
                false
            }
        }

        input.post {
            input.requestFocus()
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            imm.showSoftInput(input, InputMethodManager.SHOW_IMPLICIT)
        }
    }

  /**
   * Ancho del diálogo: ver `res/values/integers.xml` → widget_dialog_width_percent.
   * Se aplica tras setContentView para que Samsung lo respete.
   */
    private fun applyDialogSize() {
        window.setBackgroundDrawableResource(android.R.color.transparent)

        val percent = resources.getInteger(R.integer.widget_dialog_width_percent)
        val width = resources.displayMetrics.widthPixels * percent / 100

        window.setLayout(width, WindowManager.LayoutParams.WRAP_CONTENT)
        window.setGravity(Gravity.CENTER)
        val params = window.attributes
        params.width = width
        params.dimAmount = 0.6f
        window.attributes = params
    }

    private fun clearWidgetFeedback() {
        HomeWidgetPlugin.getData(this).edit()
            .remove(AddTaskWidgetProvider.PREF_LAST_FEEDBACK)
            .remove(AddTaskWidgetProvider.PREF_LAST_FEEDBACK_AT)
            .apply()
    }

    private fun submitTask(input: EditText) {
        val title = input.text.toString().trim()
        if (title.isEmpty()) {
            input.error = getString(R.string.widget_add_task_hint)
            return
        }

        val uri = Uri.parse(
            "doboard://widget/add?boardId=$selectedBoardId&title=${Uri.encode(title)}",
        )
        HomeWidgetBackgroundIntent.getBroadcast(this, uri).send()

        HomeWidgetPlugin.getData(this).edit()
            .remove(AddTaskWidgetProvider.PREF_LAST_FEEDBACK)
            .apply()

        refreshHomeWidget()
        finish()
    }

    private fun refreshHomeWidget() {
        val manager = AppWidgetManager.getInstance(this)
        val component = ComponentName(this, AddTaskWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(component)
        if (ids.isNotEmpty()) {
            val intent = Intent(this, AddTaskWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            sendBroadcast(intent)
        }
    }

    private fun styleChip(view: TextView, selected: Boolean, chip: ChipStyle) {
        view.setBackgroundResource(chip.background(selected))
        view.setTextColor(
            if (selected) Color.WHITE else getColor(chip.unselectedTextColor),
        )
    }

    private data class ChipStyle(
        val selectedBg: Int,
        val unselectedTextColor: Int,
    ) {
        fun background(selected: Boolean): Int =
            if (selected) selectedBg else R.drawable.widget_chip_unselected
    }

    companion object {
        const val EXTRA_BOARD_ID = "board_id"

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
