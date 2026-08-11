package com.wakeapp.ceoos

import android.content.Context

enum class PendingPermissionStep {
    OVERLAY,
    USAGE_ACCESS,
    ACCESSIBILITY,
}

object PermissionReturnCoordinator {
    private const val PREFS_NAME = "wakeapp_permission_return"
    private const val KEY_STEP = "pending_step"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun setPendingStep(context: Context, step: PendingPermissionStep) {
        prefs(context).edit().putString(KEY_STEP, step.name).apply()
    }

    fun clearPendingStep(context: Context) {
        prefs(context).edit().remove(KEY_STEP).apply()
    }

    fun getPendingStep(context: Context): PendingPermissionStep? {
        val raw = prefs(context).getString(KEY_STEP, null) ?: return null
        return runCatching { PendingPermissionStep.valueOf(raw) }.getOrNull()
    }

    fun parseStep(raw: String?): PendingPermissionStep? {
        val normalized = raw?.trim()?.uppercase() ?: return null
        return when (normalized) {
            "OVERLAY" -> PendingPermissionStep.OVERLAY
            "USAGE_ACCESS", "USAGEACCESS", "USAGE" -> PendingPermissionStep.USAGE_ACCESS
            "ACCESSIBILITY" -> PendingPermissionStep.ACCESSIBILITY
            else -> null
        }
    }
}
