package com.wakeapp.ceoos.presentation.launcher

import android.content.SharedPreferences
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.wakeapp.ceoos.data.launcher.LauncherAppsRepository
import com.wakeapp.ceoos.data.launcher.LauncherPackageMonitor
import com.wakeapp.ceoos.domain.block.AppBlockPolicy
import com.wakeapp.ceoos.presentation.launcher.navigation.BlockedAppNavigator
import com.wakeapp.ceoos.presentation.launcher.navigation.LauncherStarter

class HomeViewModelFactory(
    private val appsRepository: LauncherAppsRepository,
    private val appBlockPolicy: AppBlockPolicy,
    private val blockedAppNavigator: BlockedAppNavigator,
    private val launcherStarter: LauncherStarter,
    private val sharedPreferences: SharedPreferences?,
    private val packageMonitor: LauncherPackageMonitor?,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        require(modelClass.isAssignableFrom(HomeViewModel::class.java))
        return HomeViewModel(
            appsRepository = appsRepository,
            appBlockPolicy = appBlockPolicy,
            blockedAppNavigator = blockedAppNavigator,
            launcherStarter = launcherStarter,
            sharedPreferences = sharedPreferences,
            packageMonitor = packageMonitor,
        ) as T
    }
}
