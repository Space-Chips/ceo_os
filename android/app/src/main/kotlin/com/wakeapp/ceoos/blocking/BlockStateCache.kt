package com.wakeapp.ceoos.blocking

import com.wakeapp.ceoos.BlockPolicyState
import com.wakeapp.ceoos.ModeResolver
import com.wakeapp.ceoos.domain.block.BlockReason
import java.util.concurrent.ConcurrentHashMap

data class CachedBlockDecision(
    val blocked: Boolean,
    val reason: BlockReason? = null,
    val reasonKey: String? = null,
)

class BlockStateCache {
    @Volatile
    private var state: BlockPolicyState? = null

    private val decisions = ConcurrentHashMap<String, CachedBlockDecision>()

    fun update(newState: BlockPolicyState) {
        if (state === newState) return
        state = newState
        decisions.clear()
    }

    fun decisionFor(packageName: String?): CachedBlockDecision {
        val safePackage = packageName?.trim().orEmpty()
        if (safePackage.isEmpty()) return CachedBlockDecision(blocked = false)
        return decisions[safePackage] ?: computeDecision(safePackage).also {
            decisions[safePackage] = it
        }
    }

    private fun computeDecision(packageName: String): CachedBlockDecision {
        val current = state ?: return CachedBlockDecision(blocked = false)
        if (ModeResolver.isSystemExemptPackage(packageName, current)) {
            return CachedBlockDecision(blocked = false)
        }

        if (current.blackoutEnabled && !current.blackoutAllowedPackages.contains(packageName)) {
            return CachedBlockDecision(true, BlockReason.BLACKOUT_SESSION, "blackout")
        }
        if (current.focusEnabled && current.focusBlockedPackages.contains(packageName)) {
            return CachedBlockDecision(true, BlockReason.FOCUS_SESSION, "focus")
        }
        if (current.exceededPackages.contains(packageName)) {
            return CachedBlockDecision(true, BlockReason.CLASSIC_LIMIT_REACHED, "daily_limit")
        }
        if (current.classicPauseEnabled && current.classicPauseBlockedPackages.contains(packageName)) {
            return CachedBlockDecision(true, BlockReason.CLASSIC_PAUSE_BLOCKED, "scheduled_pause")
        }
        if (current.classicEnabled && current.classicBlockedPackages.contains(packageName)) {
            return CachedBlockDecision(true, BlockReason.CLASSIC_BLOCKED, "blocked_app")
        }
        return CachedBlockDecision(blocked = false)
    }
}
