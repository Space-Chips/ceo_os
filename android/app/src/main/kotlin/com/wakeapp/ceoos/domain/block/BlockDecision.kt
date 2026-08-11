package com.wakeapp.ceoos.domain.block

enum class BlockReason {
    BLACKOUT_SESSION,
    FOCUS_SESSION,
    CLASSIC_LIMIT_REACHED,
    CLASSIC_BLOCKED,
    CLASSIC_PAUSE_BLOCKED,
}

data class BlockDecision(
    val blocked: Boolean,
    val reason: BlockReason? = null,
)
