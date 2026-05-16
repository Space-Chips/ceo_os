package com.wakeapp.ceoos

import android.app.AppOpsManager
import android.content.Intent
import android.content.ComponentName
import android.provider.Settings
import android.net.Uri
import android.content.Context
import android.os.Build
import android.os.Process
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ceoos.app/focus"

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expected = ComponentName(this, AppBlockingService::class.java).flattenToString()
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.split(':').any { it.equals(expected, ignoreCase = true) }
    }

    private fun hasBlockingPermissions(): Boolean {
        return isAccessibilityServiceEnabled()
            && Settings.canDrawOverlays(this)
            && hasUsageStatsPermission()
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun prefs() = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> {
                    // Open Accessibility Settings
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    
                    // Also check Overlay permission
                    if (!Settings.canDrawOverlays(this)) {
                        val overlayIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, 
                            Uri.parse("package:$packageName"))
                        startActivity(overlayIntent)
                    }

                    if (!hasUsageStatsPermission()) {
                        val usageIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(usageIntent)
                    }
                    result.success(hasBlockingPermissions())
                }
                "isAuthorized" -> {
                    result.success(hasBlockingPermissions())
                }
                "startShield" -> {
                    val packages = call.argument<List<String>>("packages") ?: listOf()
                    prefs().edit().putBoolean("focus_shield_active", true).apply()
                    AppBlockingService.updateBlockList(packages)
                    AppBlockingService.setShieldActive(true)
                    result.success(null)
                }
                "syncClassicShieldConfig" -> {
                    val packages = call.argument<List<String>>("packages") ?: listOf()
                    val payload = org.json.JSONObject()
                    payload.put("blocked_package_names", org.json.JSONArray(packages))
                    prefs().edit().putString("classic_block_list", payload.toString()).apply()
                    AppBlockingService.updateClassicBlockList(packages)
                    result.success(null)
                }
                "syncClassicPauseSchedule" -> {
                    val packages = call.argument<List<String>>("packages") ?: listOf()
                    val payload = org.json.JSONObject()
                    payload.put("blocked_package_names", org.json.JSONArray(packages))
                    prefs().edit().putString("classic_pause_block_list", payload.toString()).apply()
                    AppBlockingService.updateClassicPauseBlockList(packages)
                    @Suppress("UNCHECKED_CAST")
                    val periods = call.argument<List<Map<String, Any?>>>("periods") ?: emptyList()
                    ClassicPauseScheduler.syncPauseSchedule(this, periods)
                    result.success(null)
                }
                "syncClassicDailyLimits" -> {
                    @Suppress("UNCHECKED_CAST")
                    val entries = call.argument<List<Map<String, Any?>>>("entries") ?: emptyList()
                    ClassicDailyLimitTracker.syncDailyLimits(this, entries)
                    result.success(null)
                }
                "setClassicShieldEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    prefs().edit().putBoolean("classic_shield_active", enabled).apply()
                    AppBlockingService.setClassicShieldActive(enabled)
                    result.success(null)
                }
                "startCeoShield" -> {
                    // Android fallback: enable shielding with currently configured block list.
                    // If Flutter passes packages, prefer them.
                    val packages = call.argument<List<String>>("packages")
                    if (packages != null && packages.isNotEmpty()) {
                        AppBlockingService.updateBlockList(packages)
                    }
                    prefs().edit().putBoolean("ceo_shield_active", true).apply()
                    AppBlockingService.setCeoShieldActive(true)
                    result.success(null)
                }
                "stopShield" -> {
                    prefs().edit()
                        .putBoolean("focus_shield_active", false)
                        .putBoolean("ceo_shield_active", false)
                        .apply()
                    AppBlockingService.setShieldActive(false)
                    result.success(null)
                }
                "isShieldActive" -> {
                    val prefs = prefs()
                    val active =
                        prefs.getBoolean("focus_shield_active", false) ||
                        prefs.getBoolean("classic_shield_active", false) ||
                        prefs.getBoolean("classic_pause_shield_active", false) ||
                        prefs.getBoolean("ceo_shield_active", false)
                    result.success(active)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
