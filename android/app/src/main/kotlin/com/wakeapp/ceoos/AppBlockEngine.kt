package com.wakeapp.ceoos

sealed class BlockDecision {
    object Allow : BlockDecision()
    data class BlockApp(val packageName: String, val reason: String) : BlockDecision()
    object IgnoreTransient : BlockDecision()
}

class AppBlockEngine(
) {
    fun evaluate(
        snapshot: ForegroundSnapshot,
        state: BlockPolicyState,
        isGateVisible: Boolean,
    ): BlockDecision {
        val packageName = snapshot.packageName?.trim().orEmpty()
        if (packageName.isEmpty()) return BlockDecision.IgnoreTransient
        if (isGateVisible && snapshot.packageName == state.wakePackageName) {
            return BlockDecision.IgnoreTransient
        }
        if (ModeResolver.isSystemExemptPackage(packageName, state)) {
            return BlockDecision.Allow
        }

        if (state.blackoutEnabled && !state.blackoutAllowedPackages.contains(packageName)) {
            return BlockDecision.BlockApp(packageName, "blackout")
        }

        if (state.focusEnabled && state.focusBlockedPackages.contains(packageName)) {
            return BlockDecision.BlockApp(packageName, "focus")
        }

        if (state.exceededPackages.contains(packageName)) {
            return BlockDecision.BlockApp(packageName, "daily_limit")
        }

        if (state.classicPauseEnabled && state.classicPauseBlockedPackages.contains(packageName)) {
            return BlockDecision.BlockApp(packageName, "scheduled_pause")
        }

        if (state.classicEnabled && state.classicBlockedPackages.contains(packageName)) {
            return BlockDecision.BlockApp(packageName, "blocked_app")
        }

        return BlockDecision.Allow
    }
}
