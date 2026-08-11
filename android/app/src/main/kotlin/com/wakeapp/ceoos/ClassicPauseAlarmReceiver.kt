package com.wakeapp.ceoos

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ClassicPauseAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ClassicPauseScheduler.evaluateAndApplyNow(context)
    }
}
