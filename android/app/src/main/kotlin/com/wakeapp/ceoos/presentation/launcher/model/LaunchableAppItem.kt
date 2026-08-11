package com.wakeapp.ceoos.presentation.launcher.model

import com.wakeapp.ceoos.domain.block.BlockReason

data class LaunchableAppItem(
    val packageName: String,
    val activityName: String,
    val label: String,
    val blocked: Boolean,
    val blockReason: BlockReason?,
)
