package com.wakeapp.ceoos

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log

class GateLauncher {
    data class GateLaunchResult(
        val launched: Boolean,
        val reason: String? = null,
    )

    private val appLabelCache = mutableMapOf<String, String>()

    fun launch(
        context: Context,
        decision: BlockDecision,
    ): GateLaunchResult {
        val payload = payloadForDecision(context.packageManager, decision)
            ?: return GateLaunchResult(launched = false, reason = "unsupported_decision")

        return try {
            val intent = Intent(context, BlockGateActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                        Intent.FLAG_ACTIVITY_NO_ANIMATION,
                )
                putExtra(BlockGateActivity.EXTRA_BLOCK_TYPE, payload.blockType)
                putExtra(BlockGateActivity.EXTRA_PACKAGE_NAME, payload.packageName)
                putExtra(BlockGateActivity.EXTRA_DOMAIN, payload.domain)
                putExtra(BlockGateActivity.EXTRA_REASON, payload.reason)
                putExtra(BlockGateActivity.EXTRA_KICKER, payload.kicker)
                putExtra(BlockGateActivity.EXTRA_TITLE, payload.title)
                putExtra(BlockGateActivity.EXTRA_SUBTITLE, payload.subtitle)
                putExtra(BlockGateActivity.EXTRA_PRIMARY_ACTION, payload.primaryAction)
                putExtra(BlockGateActivity.EXTRA_PRIMARY_LABEL, payload.primaryLabel)
            }
            context.startActivity(intent)
            GateLaunchResult(launched = true, reason = null)
        } catch (error: Exception) {
            Log.e("GateLauncher", "Error launching block gate", error)
            GateLaunchResult(
                launched = false,
                reason = "exception:${error::class.java.simpleName}",
            )
        }
    }

    fun dismiss(context: Context) {
        try {
            context.sendBroadcast(
                Intent(BlockGateActivity.ACTION_DISMISS).apply {
                    `package` = context.packageName
                },
            )
        } catch (_: Exception) {
        }
    }

    fun onGateHidden() {
        // no-op: lifecycle synchronization is handled in BlockingAccessibilityService
    }

    private fun payloadForDecision(
        packageManager: PackageManager,
        decision: BlockDecision,
    ): GatePayload? {
        return when (decision) {
            is BlockDecision.BlockApp -> {
                val appName = appLabelForPackage(packageManager, decision.packageName)
                when (decision.reason) {
                    "daily_limit" -> GatePayload(
                        blockType = "app",
                        packageName = decision.packageName,
                        domain = null,
                        target = decision.packageName,
                        reason = decision.reason,
                        kicker = "Daily limit reached",
                        title = "$appName is unavailable for now",
                        subtitle = "You have reached today's allowed time for this app. WakeApp will unlock it again tomorrow.",
                        primaryAction = "go_home",
                        primaryLabel = "Return to Home",
                    )
                    "blackout" -> GatePayload(
                        blockType = "app",
                        packageName = decision.packageName,
                        domain = null,
                        target = decision.packageName,
                        reason = decision.reason,
                        kicker = "Blackout Mode",
                        title = "$appName is blocked",
                        subtitle = "This app stays locked while Blackout Mode is active so you can stay fully off distractions.",
                        primaryAction = "go_home",
                        primaryLabel = "Return to Home",
                    )
                    "focus" -> GatePayload(
                        blockType = "app",
                        packageName = decision.packageName,
                        domain = null,
                        target = decision.packageName,
                        reason = decision.reason,
                        kicker = "Focus Mode",
                        title = "$appName is blocked",
                        subtitle = "This app is unavailable during your current Focus session.",
                        primaryAction = "go_home",
                        primaryLabel = "Return to Home",
                    )
                    "scheduled_pause" -> GatePayload(
                        blockType = "app",
                        packageName = decision.packageName,
                        domain = null,
                        target = decision.packageName,
                        reason = decision.reason,
                        kicker = "Scheduled pause",
                        title = "$appName is blocked",
                        subtitle = "This app is unavailable during the pause window you planned in WakeApp.",
                        primaryAction = "go_home",
                        primaryLabel = "Return to Home",
                    )
                    else -> GatePayload(
                        blockType = "app",
                        packageName = decision.packageName,
                        domain = null,
                        target = decision.packageName,
                        reason = decision.reason,
                        kicker = "Blocked app",
                        title = "$appName is blocked",
                        subtitle = "This app is on your blocked list in WakeApp. Open WakeApp to change the selection.",
                        primaryAction = "go_home",
                        primaryLabel = "Return to Home",
                    )
                }
            }
            else -> null
        }
    }

    private fun appLabelForPackage(packageManager: PackageManager, packageName: String): String {
        appLabelCache[packageName]?.let { return it }
        val label = try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo)?.toString()?.trim().orEmpty()
                .ifEmpty { packageName.substringAfterLast('.') }
        } catch (_: Exception) {
            packageName.substringAfterLast('.')
        }
        appLabelCache[packageName] = label
        return label
    }

    private data class GatePayload(
        val blockType: String,
        val packageName: String?,
        val domain: String?,
        val target: String,
        val reason: String,
        val kicker: String,
        val title: String,
        val subtitle: String,
        val primaryAction: String,
        val primaryLabel: String,
    )
}
