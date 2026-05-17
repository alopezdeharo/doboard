package com.adrisdev.doboard

import android.content.Intent
import android.widget.RemoteViewsService

class TodayTasksWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        TodayTasksWidgetFactory(applicationContext, intent)
}
