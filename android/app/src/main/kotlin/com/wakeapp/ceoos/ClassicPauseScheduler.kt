package com.wakeapp.ceoos

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

private data class ClassicPausePeriod(
    val id: String,
    val startMillis: Long,
    val endMillis: Long,
)

object ClassicPauseScheduler {
    private const val prefsName = "FlutterSharedPreferences"
    private const val periodsStorageKey = "classic_pause_periods_v1"
    private const val pauseActiveKey = "classic_pause_shield_active"

    fun syncPauseSchedule(context: Context, rawPeriods: List<Map<String, Any?>>) {
        val previous = readPersistedPeriods(context)
        previous.forEach { cancelPeriodAlarms(context, it) }

        val parsed = rawPeriods.mapNotNull(::parsePeriod)
        persistPeriods(context, parsed)
        parsed.forEach { schedulePeriodAlarms(context, it) }
        evaluateAndApplyNow(context)
    }

    fun rescheduleFromPersisted(context: Context) {
        val periods = readPersistedPeriods(context)
        periods.forEach { cancelPeriodAlarms(context, it) }
        periods.forEach { schedulePeriodAlarms(context, it) }
        evaluateAndApplyNow(context)
    }

    fun evaluateAndApplyNow(context: Context) {
        val now = System.currentTimeMillis()
        val active = readPersistedPeriods(context).any { period ->
            period.startMillis <= now && period.endMillis > now
        }
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(pauseActiveKey, active)
            .apply()
        AppBlockingService.setClassicPauseShieldActive(active)
    }

    private fun parsePeriod(raw: Map<String, Any?>): ClassicPausePeriod? {
        val id = raw["id"] as? String ?: return null
        val startMillis = (raw["startMillis"] as? Number)?.toLong() ?: return null
        val endMillis = (raw["endMillis"] as? Number)?.toLong() ?: return null
        if (endMillis <= startMillis) return null
        return ClassicPausePeriod(id = id, startMillis = startMillis, endMillis = endMillis)
    }

    private fun persistPeriods(context: Context, periods: List<ClassicPausePeriod>) {
        val array = JSONArray()
        periods.forEach { period ->
            val json = JSONObject()
            json.put("id", period.id)
            json.put("startMillis", period.startMillis)
            json.put("endMillis", period.endMillis)
            array.put(json)
        }
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .putString(periodsStorageKey, array.toString())
            .apply()
    }

    private fun readPersistedPeriods(context: Context): List<ClassicPausePeriod> {
        val raw = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .getString(periodsStorageKey, null)
            ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            buildList {
                for (i in 0 until array.length()) {
                    val json = array.optJSONObject(i) ?: continue
                    val id = json.optString("id")
                    val startMillis = json.optLong("startMillis", -1L)
                    val endMillis = json.optLong("endMillis", -1L)
                    if (id.isBlank() || startMillis <= 0L || endMillis <= startMillis) continue
                    add(ClassicPausePeriod(id, startMillis, endMillis))
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun schedulePeriodAlarms(context: Context, period: ClassicPausePeriod) {
        val now = System.currentTimeMillis()
        if (period.endMillis <= now) return
        if (period.startMillis > now) {
            scheduleAlarm(context, period.startMillis, startIntent(context, period))
        }
        scheduleAlarm(context, period.endMillis, endIntent(context, period))
    }

    private fun cancelPeriodAlarms(context: Context, period: ClassicPausePeriod) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(startIntent(context, period))
        alarmManager.cancel(endIntent(context, period))
    }

    private fun scheduleAlarm(context: Context, triggerAtMillis: Long, pendingIntent: PendingIntent) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            return
        }
        alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
    }

    private fun startIntent(context: Context, period: ClassicPausePeriod): PendingIntent {
        val intent = Intent(context, ClassicPauseAlarmReceiver::class.java).apply {
            action = "com.wakeapp.ceoos.CLASSIC_PAUSE_START"
            putExtra("period_id", period.id)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode(period.id, true),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun endIntent(context: Context, period: ClassicPausePeriod): PendingIntent {
        val intent = Intent(context, ClassicPauseAlarmReceiver::class.java).apply {
            action = "com.wakeapp.ceoos.CLASSIC_PAUSE_END"
            putExtra("period_id", period.id)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode(period.id, false),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun requestCode(id: String, isStart: Boolean): Int {
        return (id.hashCode() * 31) + if (isStart) 1 else 2
    }
}
