package com.wakeapp.ceoos.presentation.launcher

import com.wakeapp.ceoos.presentation.launcher.model.LaunchableAppItem

data class HomeUiState(
    val apps: List<LaunchableAppItem> = emptyList(),
    val isLoading: Boolean = false,
)
