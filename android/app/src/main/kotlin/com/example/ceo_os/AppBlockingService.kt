package com.wakeapp.ceoos

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.app.usage.UsageStatsManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.FrameLayout
import android.widget.TextView
import java.util.Calendar
import org.json.JSONObject

class AppBlockingService : AccessibilityService() {

    private var windowManager: WindowManager? = null
    private var blockView: FrameLayout? = null
    private var focusBlockedPackages = mutableSetOf<String>()
    private var classicBaseBlockedPackages = mutableSetOf<String>()
    private var classicPauseBlockedPackages = mutableSetOf<String>()
    private var dailyLimitMinutesByPackage = mutableMapOf<String, Int>()
    private var exceededDailyLimitPackages = mutableSetOf<String>()
    private var focusShieldActive = false
    private var classicShieldActive = false
    private var classicPauseShieldActive = false
    private var ceoShieldActive = false
    private var currentPackageName: String? = null
    private val usageHandler = Handler(Looper.getMainLooper())
    private val usageCheckRunnable = object : Runnable {
        override fun run() {
            evaluateDailyLimitsNow()
            if (dailyLimitMinutesByPackage.isNotEmpty()) {
                usageHandler.postDelayed(this, 15000L)
            }
        }
    }

    companion object {
        var instance: AppBlockingService? = null

        fun updateBlockList(packages: List<String>) {
            instance?.focusBlockedPackages?.clear()
            instance?.focusBlockedPackages?.addAll(packages)
            Log.d("AppBlockingService", "Updated focus block list: $packages")
        }

        fun updateClassicBlockList(packages: List<String>) {
            instance?.classicBaseBlockedPackages?.clear()
            instance?.classicBaseBlockedPackages?.addAll(packages)
            Log.d("AppBlockingService", "Updated classic base block list: $packages")
        }

        fun updateClassicPauseBlockList(packages: List<String>) {
            instance?.classicPauseBlockedPackages?.clear()
            instance?.classicPauseBlockedPackages?.addAll(packages)
            Log.d("AppBlockingService", "Updated classic pause block list: $packages")
        }

        fun updateDailyLimitConfig(config: Map<String, Int>) {
            instance?.dailyLimitMinutesByPackage?.clear()
            instance?.dailyLimitMinutesByPackage?.putAll(config)
            instance?.refreshDailyLimitConfigFromPrefs()
            instance?.scheduleDailyLimitMonitoring()
            instance?.evaluateDailyLimitsNow()
            Log.d("AppBlockingService", "Updated daily limit config: $config")
        }

        fun setShieldActive(active: Boolean) {
            instance?.focusShieldActive = active
            instance?.ceoShieldActive = false
            instance?.refreshFocusBlockListFromPrefs()
            instance?.applyShieldState()
            instance?.enforceCurrentForegroundIfNeeded()
        }

        fun setClassicShieldActive(active: Boolean) {
            instance?.classicShieldActive = active
            instance?.refreshClassicBaseBlockListFromPrefs()
            instance?.applyShieldState()
            instance?.enforceCurrentForegroundIfNeeded()
        }

        fun setClassicPauseShieldActive(active: Boolean) {
            instance?.classicPauseShieldActive = active
            instance?.refreshClassicPauseBlockListFromPrefs()
            instance?.applyShieldState()
            instance?.enforceCurrentForegroundIfNeeded()
        }

        fun setCeoShieldActive(active: Boolean) {
            instance?.ceoShieldActive = active
            if (active) {
                instance?.refreshFocusBlockListFromPrefs()
            }
            instance?.applyShieldState()
            instance?.enforceCurrentForegroundIfNeeded()
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        refreshFocusBlockListFromPrefs()
        refreshClassicBaseBlockListFromPrefs()
        refreshClassicPauseBlockListFromPrefs()
        refreshDailyLimitConfigFromPrefs()
        refreshShieldFlagsFromPrefs()
        scheduleDailyLimitMonitoring()
        enforceCurrentForegroundIfNeeded()
        Log.d("AppBlockingService", "Service Connected")
    }

    private fun refreshFocusBlockListFromPrefs() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jsonStr = prefs.getString("flutter.active_block_list", null)
            if (jsonStr != null) {
                val json = JSONObject(jsonStr)
                val packagesArray = json.optJSONArray("blocked_package_names")
                focusBlockedPackages.clear()
                if (packagesArray != null) {
                    for (i in 0 until packagesArray.length()) {
                        focusBlockedPackages.add(packagesArray.getString(i))
                    }
                }
                Log.d("AppBlockingService", "Refreshed focus block list from prefs: $focusBlockedPackages")
            }
        } catch (e: Exception) {
            Log.e("AppBlockingService", "Error refreshing focus prefs", e)
        }
    }

    private fun refreshClassicBaseBlockListFromPrefs() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jsonStr = prefs.getString("classic_block_list", null)
            classicBaseBlockedPackages.clear()
            if (jsonStr.isNullOrEmpty()) {
                return
            }
            val json = JSONObject(jsonStr)
            val packagesArray = json.optJSONArray("blocked_package_names")
            if (packagesArray != null) {
                for (i in 0 until packagesArray.length()) {
                    classicBaseBlockedPackages.add(packagesArray.getString(i))
                }
            }
            Log.d("AppBlockingService", "Refreshed classic base block list from prefs: $classicBaseBlockedPackages")
        } catch (e: Exception) {
            Log.e("AppBlockingService", "Error refreshing classic base prefs", e)
        }
    }

    private fun refreshClassicPauseBlockListFromPrefs() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jsonStr = prefs.getString("classic_pause_block_list", null)
            classicPauseBlockedPackages.clear()
            if (jsonStr.isNullOrEmpty()) {
                return
            }
            val json = JSONObject(jsonStr)
            val packagesArray = json.optJSONArray("blocked_package_names")
            if (packagesArray != null) {
                for (i in 0 until packagesArray.length()) {
                    classicPauseBlockedPackages.add(packagesArray.getString(i))
                }
            }
            Log.d("AppBlockingService", "Refreshed classic pause block list from prefs: $classicPauseBlockedPackages")
        } catch (e: Exception) {
            Log.e("AppBlockingService", "Error refreshing classic pause prefs", e)
        }
    }

    private fun refreshShieldFlagsFromPrefs() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        focusShieldActive = prefs.getBoolean("focus_shield_active", false)
        classicShieldActive = prefs.getBoolean("classic_shield_active", false)
        classicPauseShieldActive = prefs.getBoolean("classic_pause_shield_active", false)
        exceededDailyLimitPackages.clear()
        val exceededJson = prefs.getString("classic_daily_limit_exceeded_packages", null)
        if (!exceededJson.isNullOrEmpty()) {
            try {
                val array = org.json.JSONArray(exceededJson)
                for (i in 0 until array.length()) {
                    exceededDailyLimitPackages.add(array.getString(i))
                }
            } catch (_: Exception) {
            }
        }
        ceoShieldActive = prefs.getBoolean("ceo_shield_active", false)
    }

    private fun refreshDailyLimitConfigFromPrefs() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jsonStr = prefs.getString("classic_daily_limit_config", null)
            dailyLimitMinutesByPackage.clear()
            if (jsonStr.isNullOrEmpty()) {
                return
            }
            val json = JSONObject(jsonStr)
            val packagesObject = json.optJSONObject("package_limits")
            if (packagesObject != null) {
                val keys = packagesObject.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    val minutes = packagesObject.optInt(key, 0)
                    if (minutes > 0) {
                        dailyLimitMinutesByPackage[key] = minutes
                    }
                }
            }
            Log.d("AppBlockingService", "Refreshed daily limit config: $dailyLimitMinutesByPackage")
        } catch (e: Exception) {
            Log.e("AppBlockingService", "Error refreshing daily limit prefs", e)
        }
    }

    private fun effectiveBlockedPackages(): Set<String> {
        val merged = mutableSetOf<String>()
        if (focusShieldActive || ceoShieldActive) {
            merged.addAll(focusBlockedPackages)
        }
        if (classicShieldActive) {
            merged.addAll(classicBaseBlockedPackages)
        }
        if (classicPauseShieldActive) {
            merged.addAll(classicPauseBlockedPackages)
        }
        merged.addAll(exceededDailyLimitPackages)
        return merged
    }

    private fun applyShieldState() {
        if (!focusShieldActive && !classicShieldActive && !classicPauseShieldActive && !ceoShieldActive && exceededDailyLimitPackages.isEmpty()) {
            removeBlockOverlay()
        }
    }

    private fun scheduleDailyLimitMonitoring() {
        usageHandler.removeCallbacks(usageCheckRunnable)
        if (dailyLimitMinutesByPackage.isNotEmpty()) {
            usageHandler.post(usageCheckRunnable)
        }
    }

    private fun persistExceededDailyLimitPackages() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val array = org.json.JSONArray()
        exceededDailyLimitPackages.forEach { array.put(it) }
        prefs.edit()
            .putString("classic_daily_limit_exceeded_packages", array.toString())
            .putBoolean("classic_daily_limit_active", exceededDailyLimitPackages.isNotEmpty())
            .apply()
    }

    private fun queryUsageMinutesToday(packageName: String): Int {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            calendar.timeInMillis,
            System.currentTimeMillis(),
        )
        if (stats.isNullOrEmpty()) return 0
        val millis = stats
            .filter { it.packageName == packageName }
            .sumOf { it.totalTimeInForeground }
        return (millis / 60000L).toInt()
    }

    private fun evaluateDailyLimitsNow() {
        if (dailyLimitMinutesByPackage.isEmpty()) {
            exceededDailyLimitPackages.clear()
            persistExceededDailyLimitPackages()
            enforceCurrentForegroundIfNeeded()
            return
        }

        val newlyExceeded = mutableSetOf<String>()
        dailyLimitMinutesByPackage.forEach { (packageName, limitMinutes) ->
            val usedMinutes = queryUsageMinutesToday(packageName)
            if (usedMinutes >= limitMinutes) {
                newlyExceeded.add(packageName)
            }
        }
        if (newlyExceeded != exceededDailyLimitPackages) {
            exceededDailyLimitPackages = newlyExceeded
            persistExceededDailyLimitPackages()
        } else {
            persistExceededDailyLimitPackages()
        }
        enforceCurrentForegroundIfNeeded()
    }

    private fun enforceCurrentForegroundIfNeeded() {
        val candidate = currentPackageName ?: rootInActiveWindow?.packageName?.toString()
        if (candidate == null) {
            if (!focusShieldActive && !classicShieldActive && !classicPauseShieldActive && !ceoShieldActive && exceededDailyLimitPackages.isEmpty()) {
                removeBlockOverlay()
            }
            return
        }
        if (effectiveBlockedPackages().contains(candidate)) {
            showBlockOverlay(candidate)
        } else {
            removeBlockOverlay()
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        currentPackageName = event.packageName?.toString()
        evaluateDailyLimitsNow()
        if (!focusShieldActive && !classicShieldActive && !classicPauseShieldActive && !ceoShieldActive && exceededDailyLimitPackages.isEmpty()) {
            removeBlockOverlay()
            return
        }
        val packageName = currentPackageName ?: return
        if (effectiveBlockedPackages().contains(packageName)) {
            showBlockOverlay(packageName)
        } else {
            removeBlockOverlay()
        }
    }

    override fun onInterrupt() {}

    private fun showBlockOverlay(packageName: String) {
        if (blockView != null) return

        try {
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            )
            params.gravity = Gravity.CENTER

            blockView = FrameLayout(this)
            blockView?.setBackgroundColor(Color.parseColor("#000000"))

            val message = TextView(this)
            message.text = "SYSTEM_FOCUS_ACTIVE\n\nACCESS_DENIED"
            message.setTextColor(Color.parseColor("#FF5500"))
            message.textSize = 20f
            message.typeface = android.graphics.Typeface.MONOSPACE
            message.gravity = Gravity.CENTER

            val layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            )
            layoutParams.gravity = Gravity.CENTER
            blockView?.addView(message, layoutParams)

            windowManager?.addView(blockView, params)

            val homeIntent = Intent(Intent.ACTION_MAIN)
            homeIntent.addCategory(Intent.CATEGORY_HOME)
            homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(homeIntent)

        } catch (e: Exception) {
            Log.e("AppBlockingService", "Error showing overlay for $packageName", e)
        }
    }

    private fun removeBlockOverlay() {
        if (blockView != null) {
            try {
                windowManager?.removeView(blockView)
                blockView = null
            } catch (e: Exception) {
                Log.e("AppBlockingService", "Error removing overlay", e)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        usageHandler.removeCallbacks(usageCheckRunnable)
        removeBlockOverlay()
    }
}
