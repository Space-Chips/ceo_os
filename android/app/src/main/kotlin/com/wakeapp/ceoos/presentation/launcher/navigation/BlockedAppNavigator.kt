package com.wakeapp.ceoos.presentation.launcher.navigation

import android.content.Context
import com.wakeapp.ceoos.GateLauncher
import com.wakeapp.ceoos.domain.block.BlockReason

interface BlockedAppNavigator {
    fun showBlockedScreen(packageName: String, reason: BlockReason?)
}

class AndroidBlockedAppNavigator(
    private val context: Context,
    private val gateLauncher: GateLauncher = GateLauncher(),
) : BlockedAppNavigator {
    override fun showBlockedScreen(packageName: String, reason: BlockReason?) {
        val nativeReason = when (reason) {
            BlockReason.BLACKOUT_SESSION -> "blackout"
            BlockReason.FOCUS_SESSION -> "focus"
            BlockReason.CLASSIC_LIMIT_REACHED -> "daily_limit"
            null -> "blocked_app"
        }
        gateLauncher.launch(
            context,
            com.wakeapp.ceoos.BlockDecision.BlockApp(packageName, nativeReason),
        )
    }
}
