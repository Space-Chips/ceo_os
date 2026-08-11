package com.wakeapp.ceoos.blocking

import com.wakeapp.ceoos.BlockDecision
import com.wakeapp.ceoos.BlockPolicyState
import com.wakeapp.ceoos.ForegroundSnapshot

class ForegroundBlockInterceptor(
    private val blockStateCache: BlockStateCache,
) {
    fun decisionForApp(packageName: String?): CachedBlockDecision {
        return blockStateCache.decisionFor(packageName)
    }

    fun decisionForSnapshot(
        snapshot: ForegroundSnapshot,
        policyState: BlockPolicyState,
        evaluateBrowser: (ForegroundSnapshot, BlockPolicyState) -> BlockDecision,
    ): BlockDecision {
        if (!snapshot.isBrowser) {
            val cached = blockStateCache.decisionFor(snapshot.packageName)
            return if (cached.blocked && snapshot.packageName != null) {
                BlockDecision.BlockApp(snapshot.packageName, cached.reasonKey ?: "blocked_app")
            } else {
                BlockDecision.Allow
            }
        }
        return evaluateBrowser(snapshot, policyState)
    }
}
