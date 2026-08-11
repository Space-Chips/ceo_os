package com.wakeapp.ceoos.data.launcher

interface LauncherAppsRepository {
    suspend fun getLaunchableApps(): List<LauncherAppEntry>
    fun registerCallbacks()
    fun unregisterCallbacks()
}
