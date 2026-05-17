package com.wakeapp.ceoos

import android.content.Context
import org.json.JSONObject

object ClassicDailyLimitTracker {
    private const val prefsName = "FlutterSharedPreferences"
    private const val configStorageKey = "classic_daily_limit_config"

    fun syncDailyLimits(context: Context, rawEntries: List<Map<String, Any?>>) {
        val packageLimits = linkedMapOf<String, Int>()
        rawEntries.forEach { raw ->
            val selector = (raw["selector"] as? String)?.trim().orEmpty()
            val limitMinutes = (raw["limitMinutes"] as? Number)?.toInt() ?: 0
            if (selector.isEmpty() || limitMinutes <= 0) return@forEach
            val existing = packageLimits[selector]
            if (existing == null || existing > limitMinutes) {
                packageLimits[selector] = limitMinutes
            }
        }

        val limitsObject = JSONObject()
        packageLimits.forEach { (pkg, minutes) ->
            limitsObject.put(pkg, minutes)
        }
        val payload = JSONObject().put("package_limits", limitsObject)
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            .edit()
            .putString(configStorageKey, payload.toString())
            .apply()

        AppBlockingService.updateDailyLimitConfig(packageLimits)
    }
}
