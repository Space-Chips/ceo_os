package com.wakeapp.ceoos.domain.block

import com.wakeapp.ceoos.BlockPolicyState
import com.wakeapp.ceoos.ModeResolver

class GetBlockDecisionUseCase(
    private val stateProvider: () -> BlockPolicyState,
) : AppBlockPolicy {
    override fun isBlocked(packageName: String): BlockDecision {
        val normalizedPackage = packageName.trim()
        if (normalizedPackage.isEmpty()) {
            return BlockDecision(blocked = false)
        }

        val state = stateProvider()
        if (ModeResolver.isSystemExemptPackage(normalizedPackage, state)) {
            return BlockDecision(blocked = false)
        }

        return when {
            state.blackoutEnabled && !state.blackoutAllowedPackages.contains(normalizedPackage) -> {
                BlockDecision(blocked = true, reason = BlockReason.BLACKOUT_SESSION)
            }
            state.focusEnabled && state.focusBlockedPackages.contains(normalizedPackage) -> {
                BlockDecision(blocked = true, reason = BlockReason.FOCUS_SESSION)
            }
            state.exceededPackages.contains(normalizedPackage) -> {
                BlockDecision(blocked = true, reason = BlockReason.CLASSIC_LIMIT_REACHED)
            }
            state.classicEnabled && state.classicBlockedPackages.contains(normalizedPackage) -> {
                BlockDecision(blocked = true, reason = BlockReason.CLASSIC_BLOCKED)
            }
            state.classicPauseEnabled && state.classicPauseBlockedPackages.contains(normalizedPackage) -> {
                BlockDecision(blocked = true, reason = BlockReason.CLASSIC_PAUSE_BLOCKED)
            }
            else -> BlockDecision(blocked = false)
        }
    }
}
