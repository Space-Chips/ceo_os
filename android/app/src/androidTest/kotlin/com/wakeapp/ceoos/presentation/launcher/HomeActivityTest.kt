package com.wakeapp.ceoos.presentation.launcher

import android.content.Context
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import androidx.test.core.app.ActivityScenario
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.wakeapp.ceoos.R
import com.wakeapp.ceoos.data.launcher.LauncherAppEntry
import com.wakeapp.ceoos.data.launcher.LauncherAppsRepository
import com.wakeapp.ceoos.data.launcher.LauncherPackageMonitor
import com.wakeapp.ceoos.domain.block.AppBlockPolicy
import com.wakeapp.ceoos.domain.block.BlockDecision
import com.wakeapp.ceoos.domain.block.BlockReason
import com.wakeapp.ceoos.presentation.launcher.navigation.BlockedAppNavigator
import com.wakeapp.ceoos.presentation.launcher.navigation.LauncherStarter
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class HomeActivityTest {
    private lateinit var appContext: Context
    private lateinit var fakeRepo: FakeLauncherAppsRepository
    private lateinit var fakePolicy: MutablePolicy
    private lateinit var fakeNavigator: RecordingBlockedNavigator
    private lateinit var fakeStarter: RecordingLauncherStarter
    private lateinit var fakePrefsName: String

    @Before
    fun setUp() {
        appContext = ApplicationProvider.getApplicationContext()
        fakeRepo = FakeLauncherAppsRepository(
            listOf(
                LauncherAppEntry(
                    packageName = "com.example.blocked",
                    activityName = "com.example.blocked.MainActivity",
                    label = "Blocked",
                ),
                LauncherAppEntry(
                    packageName = "com.example.allowed",
                    activityName = "com.example.allowed.MainActivity",
                    label = "Allowed",
                ),
            ),
        )
        fakePolicy = MutablePolicy(
            mutableMapOf(
                "com.example.blocked" to BlockDecision(true, BlockReason.FOCUS_SESSION),
                "com.example.allowed" to BlockDecision(false, null),
            ),
        )
        fakeNavigator = RecordingBlockedNavigator()
        fakeStarter = RecordingLauncherStarter()
        fakePrefsName = "launcher_test_${System.nanoTime()}"

        HomeLauncherOverrides.appsRepository = fakeRepo
        HomeLauncherOverrides.appBlockPolicy = fakePolicy
        HomeLauncherOverrides.blockedAppNavigator = fakeNavigator
        HomeLauncherOverrides.launcherStarter = fakeStarter
        HomeLauncherOverrides.packageMonitor = LauncherPackageMonitor(appContext) {}
        HomeLauncherOverrides.sharedPreferences =
            appContext.getSharedPreferences(fakePrefsName, Context.MODE_PRIVATE)
    }

    @After
    fun tearDown() {
        HomeLauncherOverrides.clear()
    }

    @Test
    fun blocked_icon_is_dimmed_on_home() {
        val scenario = launchHome()
        try {
            val alpha = iconAlphaForPosition(scenario, R.id.home_recycler, 0)
            assertTrue(alpha < 1f)
        } finally {
            scenario.close()
        }
    }

    @Test
    fun blocked_click_opens_gate_instead_of_launching() {
        val scenario = launchHome()
        try {
            clickItemAt(scenario, R.id.home_recycler, 0)
            InstrumentationRegistry.getInstrumentation().waitForIdleSync()

            assertEquals("com.example.blocked", fakeNavigator.lastPackageName)
            assertEquals(BlockReason.FOCUS_SESSION, fakeNavigator.lastReason)
            assertEquals(null, fakeStarter.lastPackageName)
        } finally {
            scenario.close()
        }
    }

    @Test
    fun allowed_click_launches_normally() {
        val scenario = launchHome()
        try {
            clickItemAt(scenario, R.id.home_recycler, 1)
            InstrumentationRegistry.getInstrumentation().waitForIdleSync()

            assertEquals("com.example.allowed", fakeStarter.lastPackageName)
            assertEquals("com.example.allowed.MainActivity", fakeStarter.lastActivityName)
            assertEquals(null, fakeNavigator.lastPackageName)
        } finally {
            scenario.close()
        }
    }

    @Test
    fun refresh_updates_home_and_drawer_consistently() {
        fakePolicy.setDecision("com.example.allowed", BlockDecision(false, null))
        val scenario = launchHome()
        try {
            val initialAlpha = iconAlphaForPosition(scenario, R.id.home_recycler, 1)
            assertEquals(1f, initialAlpha, 0.01f)

            fakePolicy.setDecision(
                "com.example.allowed",
                BlockDecision(true, BlockReason.CLASSIC_LIMIT_REACHED),
            )

            scenario.onActivity {
                it.homeViewModel.onResumeRefresh()
                it.openDrawer()
            }

            waitForRecyclerReady(scenario, R.id.drawer_recycler)
            val homeAlpha = iconAlphaForPosition(scenario, R.id.home_recycler, 1)
            val drawerAlpha = iconAlphaForPosition(scenario, R.id.drawer_recycler, 1)

            assertTrue(homeAlpha < 1f)
            assertTrue(drawerAlpha < 1f)
        } finally {
            scenario.close()
        }
    }

    private fun launchHome(): ActivityScenario<HomeActivity> {
        val scenario = ActivityScenario.launch(HomeActivity::class.java)
        waitForRecyclerReady(scenario, R.id.home_recycler)
        return scenario
    }

    private fun waitForRecyclerReady(
        scenario: ActivityScenario<HomeActivity>,
        recyclerId: Int,
    ) {
        repeat(40) {
            var ready = false
            scenario.onActivity { activity ->
                val recycler = activity.findViewById<RecyclerView>(recyclerId)
                ready =
                    recycler.adapter?.itemCount?.let { count ->
                        count > 0 && recycler.findViewHolderForAdapterPosition(0) != null
                    } == true
            }
            if (ready) return
            InstrumentationRegistry.getInstrumentation().waitForIdleSync()
            Thread.sleep(50)
        }
        throw AssertionError("RecyclerView $recyclerId did not become ready")
    }

    private fun clickItemAt(
        scenario: ActivityScenario<HomeActivity>,
        recyclerId: Int,
        position: Int,
    ) {
        scenario.onActivity { activity ->
            val recycler = activity.findViewById<RecyclerView>(recyclerId)
            val holder = recycler.findViewHolderForAdapterPosition(position)
                ?: throw AssertionError("No ViewHolder at position $position for recycler $recyclerId")
            holder.itemView.performClick()
        }
    }

    private fun iconAlphaForPosition(
        scenario: ActivityScenario<HomeActivity>,
        recyclerId: Int,
        position: Int,
    ): Float {
        var alpha = 1f
        scenario.onActivity { activity ->
            val recycler = activity.findViewById<RecyclerView>(recyclerId)
            val holder = recycler.findViewHolderForAdapterPosition(position)
                ?: throw AssertionError("No ViewHolder at position $position for recycler $recyclerId")
            alpha = holder.itemView.findViewById<ImageView>(R.id.app_icon).alpha
        }
        return alpha
    }

    private class FakeLauncherAppsRepository(
        private val entries: List<LauncherAppEntry>,
    ) : LauncherAppsRepository {
        override suspend fun getLaunchableApps(): List<LauncherAppEntry> = entries
        override fun registerCallbacks() = Unit
        override fun unregisterCallbacks() = Unit
    }

    private class MutablePolicy(
        private val decisions: MutableMap<String, BlockDecision>,
    ) : AppBlockPolicy {
        override fun isBlocked(packageName: String): BlockDecision {
            return decisions[packageName] ?: BlockDecision(false, null)
        }

        fun setDecision(packageName: String, decision: BlockDecision) {
            decisions[packageName] = decision
        }
    }

    private class RecordingBlockedNavigator : BlockedAppNavigator {
        var lastPackageName: String? = null
        var lastReason: BlockReason? = null

        override fun showBlockedScreen(packageName: String, reason: BlockReason?) {
            lastPackageName = packageName
            lastReason = reason
        }
    }

    private class RecordingLauncherStarter : LauncherStarter {
        var lastPackageName: String? = null
        var lastActivityName: String? = null

        override fun start(packageName: String, activityName: String) {
            lastPackageName = packageName
            lastActivityName = activityName
        }
    }
}
