package com.wakeapp.ceoos.presentation.launcher

import android.app.WallpaperManager
import android.content.Context
import android.os.Bundle
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import androidx.activity.addCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.isVisible
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.wakeapp.ceoos.BlockPolicyRepository
import com.wakeapp.ceoos.R
import com.wakeapp.ceoos.data.launcher.AndroidLauncherAppsRepository
import com.wakeapp.ceoos.data.launcher.LauncherPackageMonitor
import com.wakeapp.ceoos.domain.block.GetBlockDecisionUseCase
import com.wakeapp.ceoos.presentation.launcher.navigation.AndroidBlockedAppNavigator
import com.wakeapp.ceoos.presentation.launcher.navigation.AndroidLauncherStarter
import kotlinx.coroutines.launch
import kotlin.math.max

class HomeActivity : AppCompatActivity() {
    lateinit var homeViewModel: HomeViewModel
        private set

    private lateinit var homeRecycler: RecyclerView
    private lateinit var drawerContainer: FrameLayout
    private lateinit var allAppsButton: TextView
    private lateinit var homeAdapter: AppIconAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_home)

        homeRecycler = findViewById(R.id.home_recycler)
        drawerContainer = findViewById(R.id.drawer_container)
        allAppsButton = findViewById(R.id.all_apps_button)

        applyWallpaper()
        configureInsets()
        configureViewModel()
        configureRecycler()
        configureDrawerButton()
        configureBackHandling()

        lifecycleScope.launch {
            repeatOnLifecycle(androidx.lifecycle.Lifecycle.State.STARTED) {
                homeViewModel.uiState.collect { state ->
                    homeAdapter.submitList(state.apps)
                }
            }
        }

        if (savedInstanceState == null) {
            homeViewModel.loadApps()
        }
    }

    override fun onResume() {
        super.onResume()
        homeViewModel.onResumeRefresh()
    }

    fun openDrawer() {
        drawerContainer.isVisible = true
        val existing = supportFragmentManager.findFragmentByTag(APP_DRAWER_TAG)
        if (existing == null) {
            supportFragmentManager.beginTransaction()
                .add(R.id.drawer_container, AppDrawerFragment(), APP_DRAWER_TAG)
                .commitNowAllowingStateLoss()
        } else {
            supportFragmentManager.beginTransaction()
                .show(existing)
                .commitNowAllowingStateLoss()
        }
    }

    fun closeDrawer() {
        val existing = supportFragmentManager.findFragmentByTag(APP_DRAWER_TAG)
        if (existing != null) {
            supportFragmentManager.beginTransaction()
                .hide(existing)
                .commitNowAllowingStateLoss()
        }
        drawerContainer.isVisible = false
    }

    fun isDrawerVisible(): Boolean = drawerContainer.isVisible

    private fun configureViewModel() {
        val appContext = applicationContext
        lateinit var packageMonitor: LauncherPackageMonitor
        packageMonitor = HomeLauncherOverrides.packageMonitor
            ?: LauncherPackageMonitor(appContext) { homeViewModel.loadApps() }

        val appsRepository = HomeLauncherOverrides.appsRepository
            ?: AndroidLauncherAppsRepository(appContext, packageMonitor)
        val sharedPreferences = HomeLauncherOverrides.sharedPreferences
            ?: getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val appBlockPolicy = HomeLauncherOverrides.appBlockPolicy
            ?: GetBlockDecisionUseCase {
                BlockPolicyRepository.readState(
                    context = appContext,
                    homePackages = BlockPolicyRepository.homePackages(appContext),
                )
            }
        val blockedNavigator = HomeLauncherOverrides.blockedAppNavigator
            ?: AndroidBlockedAppNavigator(appContext)
        val launcherStarter = HomeLauncherOverrides.launcherStarter
            ?: AndroidLauncherStarter(appContext)

        val factory = HomeViewModelFactory(
            appsRepository = appsRepository,
            appBlockPolicy = appBlockPolicy,
            blockedAppNavigator = blockedNavigator,
            launcherStarter = launcherStarter,
            sharedPreferences = sharedPreferences,
            packageMonitor = packageMonitor,
        )
        homeViewModel = ViewModelProvider(this, factory)[HomeViewModel::class.java]
    }

    private fun configureRecycler() {
        homeAdapter = AppIconAdapter(homeViewModel::onAppClicked)
        homeRecycler.apply {
            layoutManager = GridLayoutManager(this@HomeActivity, calculateSpanCount())
            adapter = homeAdapter
            itemAnimator = null
        }
    }

    private fun configureDrawerButton() {
        allAppsButton.setOnClickListener {
            if (isDrawerVisible()) {
                closeDrawer()
            } else {
                openDrawer()
            }
        }
    }

    private fun configureBackHandling() {
        onBackPressedDispatcher.addCallback(this) {
            if (isDrawerVisible()) {
                closeDrawer()
            }
        }
    }

    private fun applyWallpaper() {
        val root: View = findViewById(R.id.home_root)
        try {
            val wallpaper = WallpaperManager.getInstance(this).drawable ?: return
            root.background = wallpaper
            window.setBackgroundDrawable(
                wallpaper.constantState?.newDrawable()?.mutate() ?: wallpaper,
            )
        } catch (_: Exception) {
        }
    }

    private fun configureInsets() {
        val root: View = findViewById(R.id.home_root)
        ViewCompat.setOnApplyWindowInsetsListener(root) { _, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            homeRecycler.setPadding(
                homeRecycler.paddingLeft,
                max(homeRecycler.paddingTop, bars.top + dp(12)),
                homeRecycler.paddingRight,
                max(homeRecycler.paddingBottom, bars.bottom + dp(72)),
            )
            allAppsButton.translationY = -bars.bottom.toFloat()
            insets
        }
    }

    private fun calculateSpanCount(): Int {
        val widthDp = resources.configuration.screenWidthDp
        return max(4, widthDp / 88)
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    companion object {
        private const val APP_DRAWER_TAG = "app_drawer"
    }
}
