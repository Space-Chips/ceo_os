package com.wakeapp.ceoos

import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Locale

open class MainActivity : FlutterActivity() {
    private enum class AndroidProtectionStep {
        OVERLAY,
        ACCESSIBILITY,
        USAGE_ACCESS,
        COMPLETE,
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expected = ComponentName(this, BlockingAccessibilityService::class.java).flattenToString()
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        return enabled.split(':').any { it.equals(expected, ignoreCase = true) }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun hasBlockingPermissions(): Boolean {
        return hasOverlayPermission() &&
            isAccessibilityServiceEnabled() &&
            hasUsageStatsPermission()
    }

    private fun nextMissingProtectionStep(): AndroidProtectionStep {
        return when {
            !isAccessibilityServiceEnabled() -> AndroidProtectionStep.ACCESSIBILITY
            !hasUsageStatsPermission() -> AndroidProtectionStep.USAGE_ACCESS
            !hasOverlayPermission() -> AndroidProtectionStep.OVERLAY
            else -> AndroidProtectionStep.COMPLETE
        }
    }

    private fun openNextProtectionSettings(): Boolean {
        val intent = when (nextMissingProtectionStep()) {
            AndroidProtectionStep.OVERLAY -> Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                android.net.Uri.fromParts("package", packageName, null),
            )
            AndroidProtectionStep.ACCESSIBILITY -> Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            AndroidProtectionStep.USAGE_ACCESS -> Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            AndroidProtectionStep.COMPLETE -> Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                android.net.Uri.fromParts("package", packageName, null),
            )
        }.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
        return true
    }

    private fun authorizationStatus(): String {
        return if (hasBlockingPermissions()) "approved" else "denied"
    }

    private fun accessibilityStatus(): String {
        return if (isAccessibilityServiceEnabled()) "approved" else "denied"
    }

    private fun usageAccessStatus(): String {
        return if (hasUsageStatsPermission()) "approved" else "denied"
    }

    private fun overlayStatus(): String {
        return if (hasOverlayPermission()) "approved" else "denied"
    }

    private fun nextProtectionStepName(): String {
        return when (nextMissingProtectionStep()) {
            AndroidProtectionStep.OVERLAY -> "overlay"
            AndroidProtectionStep.ACCESSIBILITY -> "accessibility"
            AndroidProtectionStep.USAGE_ACCESS -> "usage_access"
            AndroidProtectionStep.COMPLETE -> "complete"
        }
    }

    private fun openAccessibilitySettings(): Boolean {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
        return true
    }

    private fun openUsageAccessSettings(): Boolean {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
        return true
    }

    private fun openOverlaySettings(): Boolean {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                android.net.Uri.fromParts("package", packageName, null),
            )
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = android.net.Uri.fromParts("package", packageName, null)
            }
        }.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
        return true
    }

    private fun isSystemApp(applicationInfo: ApplicationInfo): Boolean {
        val flags = applicationInfo.flags
        return (flags and ApplicationInfo.FLAG_SYSTEM) != 0 ||
            (flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
    }

    private fun drawableToPngBytes(drawable: android.graphics.drawable.Drawable): ByteArray? {
        return try {
            val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
                drawable.bitmap
            } else {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
                Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { bitmap ->
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                }
            }
            ByteArrayOutputStream().use { stream ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                stream.toByteArray()
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun listLaunchableApps(result: MethodChannel.Result) {
        try {
            val launchIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            val activities = packageManager.queryIntentActivities(launchIntent, 0)
            val blockedPackages = BlockPolicyRepository.getBlockedPackages(this)
            val apps = linkedMapOf<String, Map<String, Any?>>()

            for (resolveInfo in activities) {
                val activityInfo = resolveInfo.activityInfo ?: continue
                val packageName = activityInfo.packageName?.trim().orEmpty()
                if (packageName.isEmpty() || packageName == this.packageName) continue
                val appInfo = activityInfo.applicationInfo ?: continue
                if (isSystemApp(appInfo)) continue

                if (!apps.containsKey(packageName)) {
                    val label = resolveInfo.loadLabel(packageManager)?.toString()?.trim()
                    val iconBytes = drawableToPngBytes(resolveInfo.loadIcon(packageManager))
                    apps[packageName] = mapOf(
                        "name" to if (!label.isNullOrEmpty()) label else packageName,
                        "packageName" to packageName,
                        "icon" to iconBytes,
                        "isBlocked" to blockedPackages.contains(packageName),
                    )
                }
            }

            result.success(
                apps.values.sortedBy {
                    (it["name"] as? String)?.lowercase(Locale.getDefault()) ?: ""
                },
            )
        } catch (error: Exception) {
            result.error("LIST_APPS_FAILED", error.message, null)
        }
    }

    private fun launchExternalApp(packageName: String?): Boolean {
        val targetPackage = packageName?.trim().orEmpty()
        if (targetPackage.isEmpty() || targetPackage == this.packageName) {
            return false
        }
        val intent = packageManager.getLaunchIntentForPackage(targetPackage)
            ?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
            }
            ?: return false
        startActivity(intent)
        return true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ceoos.app/app_env")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTestFlight" -> result.success(false)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ceoos.app/focus")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermissions" -> result.success(openNextProtectionSettings())
                    "isAuthorized" -> result.success(hasBlockingPermissions())
                    "getAuthorizationStatus" -> result.success(authorizationStatus())
                    "getAccessibilityStatus" -> result.success(accessibilityStatus())
                    "getUsageAccessStatus" -> result.success(usageAccessStatus())
                    "getOverlayStatus" -> result.success(overlayStatus())
                    "getNextProtectionStep" -> result.success(nextProtectionStepName())
                    "openSystemSettings" -> result.success(openNextProtectionSettings())
                    "openAccessibilitySettings" -> result.success(openAccessibilitySettings())
                    "openUsageAccessSettings" -> result.success(openUsageAccessSettings())
                    "openOverlaySettings" -> result.success(openOverlaySettings())
                    "setPendingPermissionReturn" -> {
                        val raw = call.argument<String>("step")
                        val step = PermissionReturnCoordinator.parseStep(raw)
                        if (step != null) {
                            PermissionReturnCoordinator.setPendingStep(this, step)
                        }
                        result.success(null)
                    }
                    "clearPendingPermissionReturn" -> {
                        PermissionReturnCoordinator.clearPendingStep(this)
                        result.success(null)
                    }
                    "cacheSelection" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        val categories = call.argument<List<String>>("categories") ?: emptyList()
                        BlockPolicyRepository.updateFocusSelection(this, packages, categories)
                        result.success(null)
                    }
                    "listLaunchableApps" -> listLaunchableApps(result)
                    "launchExternalApp" -> {
                        result.success(launchExternalApp(call.argument<String>("packageName")))
                    }
                    "getBlockingDebugState" -> result.success(BlockingAccessibilityService.debugSnapshot())
                    "startShield" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        BlockPolicyRepository.updateClassicShieldConfig(this, packages, emptyList())
                        BlockPolicyRepository.setClassicShieldActive(this, true)
                        BlockPolicyRepository.setFocusShieldActive(this, false)
                        BlockPolicyRepository.setCeoShieldActive(this, false)
                        BlockingAccessibilityService.requestImmediateEvaluation()
                        result.success(null)
                    }
                    "syncClassicShieldConfig" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        val websites = call.argument<List<String>>("websites") ?: emptyList()
                        BlockPolicyRepository.updateClassicShieldConfig(this, packages, websites)
                        BlockingAccessibilityService.requestImmediateEvaluation()
                        result.success(null)
                    }
                    "syncClassicPauseSchedule" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        val websites = call.argument<List<String>>("websites") ?: emptyList()
                        BlockPolicyRepository.updateClassicPauseConfig(this, packages, websites)
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
                        BlockPolicyRepository.setClassicShieldActive(this, enabled)
                        BlockingAccessibilityService.requestImmediateEvaluation()
                        result.success(null)
                    }
                    "updateBlackoutAllowlist" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        BlockPolicyRepository.updateBlackoutAllowlist(this, packages)
                        BlockingAccessibilityService.requestImmediateEvaluation()
                        result.success(null)
                    }
                    "startCeoShield" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        if (packages.isNotEmpty()) {
                            BlockPolicyRepository.updateBlackoutAllowlist(this, packages)
                        }
                        BlockPolicyRepository.setFocusShieldActive(this, false)
                        BlockPolicyRepository.setCeoShieldActive(this, true)
                        BlockingAccessibilityService.requestImmediateEvaluation()
                        result.success(null)
                    }
                    "stopShield" -> {
                        BlockPolicyRepository.stopShielding(this)
                        BlockingAccessibilityService.requestImmediateEvaluation()
                        result.success(null)
                    }
                    "isShieldActive" -> {
                        val state = BlockPolicyRepository.readState(
                            context = this,
                            homePackages = BlockPolicyRepository.homePackages(this),
                        )
                        result.success(
                            state.focusEnabled ||
                                state.blackoutEnabled ||
                                state.classicEnabled ||
                                state.classicPauseEnabled ||
                                state.exceededPackages.isNotEmpty() ||
                                state.exceededDomains.isNotEmpty(),
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
