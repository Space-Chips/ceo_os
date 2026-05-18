package com.wakeapp.ceoos.presentation.launcher

import android.content.SharedPreferences
import com.wakeapp.ceoos.data.launcher.LauncherAppsRepository
import com.wakeapp.ceoos.data.launcher.LauncherPackageMonitor
import com.wakeapp.ceoos.domain.block.AppBlockPolicy
import com.wakeapp.ceoos.presentation.launcher.navigation.BlockedAppNavigator
import com.wakeapp.ceoos.presentation.launcher.navigation.LauncherStarter

object HomeLauncherOverrides {
    @Volatile
    var appsRepository: LauncherAppsRepository? = null

    @Volatile
    var appBlockPolicy: AppBlockPolicy? = null

    @Volatile
    var blockedAppNavigator: BlockedAppNavigator? = null

    @Volatile
    var launcherStarter: LauncherStarter? = null

    @Volatile
    var packageMonitor: LauncherPackageMonitor? = null

    @Volatile
    var sharedPreferences: SharedPreferences? = null

    fun clear() {
        appsRepository = null
        appBlockPolicy = null
        blockedAppNavigator = null
        launcherStarter = null
        packageMonitor = null
        sharedPreferences = null
    }
}
