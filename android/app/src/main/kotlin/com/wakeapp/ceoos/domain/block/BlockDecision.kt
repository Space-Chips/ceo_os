package com.wakeapp.ceoos.domain.block

enum class BlockReason {
    BLACKOUT_SESSION,
    FOCUS_SESSION,
    CLASSIC_LIMIT_REACHED,
}

data class BlockDecision(
    val blocked: Boolean,
    val reason: BlockReason? = null,
)
