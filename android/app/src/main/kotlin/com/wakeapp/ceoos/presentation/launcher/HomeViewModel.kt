package com.wakeapp.ceoos.presentation.launcher

import android.content.SharedPreferences
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wakeapp.ceoos.data.launcher.LauncherAppEntry
import com.wakeapp.ceoos.data.launcher.LauncherAppsRepository
import com.wakeapp.ceoos.data.launcher.LauncherPackageMonitor
import com.wakeapp.ceoos.domain.block.AppBlockPolicy
import com.wakeapp.ceoos.domain.block.BlockDecision
import com.wakeapp.ceoos.presentation.launcher.model.LaunchableAppItem
import com.wakeapp.ceoos.presentation.launcher.navigation.BlockedAppNavigator
import com.wakeapp.ceoos.presentation.launcher.navigation.LauncherStarter
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class HomeViewModel(
    private val appsRepository: LauncherAppsRepository,
    private val appBlockPolicy: AppBlockPolicy,
    private val blockedAppNavigator: BlockedAppNavigator,
    private val launcherStarter: LauncherStarter,
    private val sharedPreferences: SharedPreferences? = null,
    private val packageMonitor: LauncherPackageMonitor? = null,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.Default,
) : ViewModel() {
    private val _uiState = MutableStateFlow(HomeUiState(isLoading = true))
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    private var lastEntries: List<LauncherAppEntry> = emptyList()
    private val decisionCache = linkedMapOf<String, BlockDecision>()
    private var lastClickedPackage: String? = null
    private var lastClickAtMillis: Long = 0L

    private val prefsListener =
        SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key in observedPolicyKeys) {
                refreshBlockStates()
            }
        }

    private val observedPolicyKeys = setOf(
        "focus_shield_active",
        "ceo_shield_active",
        "classic_daily_limit_exceeded_packages",
        "flutter.active_block_list",
        "blackout_allowed_packages",
    )

    init {
        sharedPreferences?.registerOnSharedPreferenceChangeListener(prefsListener)
        appsRepository.registerCallbacks()
        packageMonitor?.register()
    }

    fun loadApps() {
        viewModelScope.launch(ioDispatcher) {
            _uiState.value = _uiState.value.copy(isLoading = true)
            lastEntries = appsRepository.getLaunchableApps()
            val items = lastEntries.map(::toLaunchableItem)
            _uiState.value = HomeUiState(apps = items, isLoading = false)
        }
    }

    fun refreshBlockStates() {
        val entries = lastEntries
        if (entries.isEmpty()) {
            loadApps()
            return
        }
        viewModelScope.launch(ioDispatcher) {
            val items = entries.map(::toLaunchableItem)
            _uiState.value = _uiState.value.copy(apps = items, isLoading = false)
        }
    }

    fun onResumeRefresh() {
        refreshBlockStates()
    }

    fun onAppClicked(item: LaunchableAppItem) {
        val now = System.currentTimeMillis()
        if (item.packageName == lastClickedPackage && now - lastClickAtMillis < 450L) {
            return
        }
        lastClickedPackage = item.packageName
        lastClickAtMillis = now

        val decision = appBlockPolicy.isBlocked(item.packageName)
        decisionCache[item.packageName] = decision
        if (decision.blocked) {
            blockedAppNavigator.showBlockedScreen(
                packageName = item.packageName,
                reason = decision.reason,
            )
            return
        }

        val finalDecision = appBlockPolicy.isBlocked(item.packageName)
        decisionCache[item.packageName] = finalDecision
        if (finalDecision.blocked) {
            blockedAppNavigator.showBlockedScreen(
                packageName = item.packageName,
                reason = finalDecision.reason,
            )
            return
        }

        launcherStarter.start(item.packageName, item.activityName)
    }

    override fun onCleared() {
        sharedPreferences?.unregisterOnSharedPreferenceChangeListener(prefsListener)
        packageMonitor?.unregister()
        appsRepository.unregisterCallbacks()
        super.onCleared()
    }

    private fun toLaunchableItem(entry: LauncherAppEntry): LaunchableAppItem {
        val decision = appBlockPolicy.isBlocked(entry.packageName)
        decisionCache[entry.packageName] = decision
        return LaunchableAppItem(
            packageName = entry.packageName,
            activityName = entry.activityName,
            label = entry.label,
            blocked = decision.blocked,
            blockReason = decision.reason,
        )
    }
}
