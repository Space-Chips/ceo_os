package com.wakeapp.ceoos.blocking

import android.content.Context
import com.wakeapp.ceoos.BlockDecision
import com.wakeapp.ceoos.GateLauncher
import com.wakeapp.ceoos.domain.block.BlockReason

class BlockingNavigator(
    private val gateLauncher: GateLauncher = GateLauncher(),
) {
    fun showBlockedScreen(
        context: Context,
        packageName: String,
        reason: BlockReason?,
        reasonKey: String?,
    ): GateLauncher.GateLaunchResult {
        val decision = BlockDecision.BlockApp(
            packageName = packageName,
            reason = reasonKey ?: mapReasonKey(reason),
        )
        return gateLauncher.launch(context, decision)
    }

    fun dismiss(context: Context) {
        gateLauncher.dismiss(context)
    }

    private fun mapReasonKey(reason: BlockReason?): String {
        return when (reason) {
            BlockReason.BLACKOUT_SESSION -> "blackout"
            BlockReason.FOCUS_SESSION -> "focus"
            BlockReason.CLASSIC_LIMIT_REACHED -> "daily_limit"
            BlockReason.CLASSIC_PAUSE_BLOCKED -> "scheduled_pause"
            BlockReason.CLASSIC_BLOCKED -> "blocked_app"
            else -> "blocked_app"
        }
    }
}
