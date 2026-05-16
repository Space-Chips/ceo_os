package com.wakeapp.ceoos.presentation.launcher

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.wakeapp.ceoos.data.launcher.LauncherAppEntry
import com.wakeapp.ceoos.data.launcher.LauncherAppsRepository
import com.wakeapp.ceoos.domain.block.AppBlockPolicy
import com.wakeapp.ceoos.domain.block.BlockDecision
import com.wakeapp.ceoos.domain.block.BlockReason
import com.wakeapp.ceoos.presentation.launcher.model.LaunchableAppItem
import com.wakeapp.ceoos.presentation.launcher.navigation.BlockedAppNavigator
import com.wakeapp.ceoos.presentation.launcher.navigation.LauncherStarter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TestWatcher
import org.junit.runner.Description
import java.util.ArrayDeque

@OptIn(ExperimentalCoroutinesApi::class)
class HomeViewModelTest {
    @get:Rule
    val instantTaskExecutorRule = InstantTaskExecutorRule()

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun `loadApps maps block state into ui items`() = runTest {
        val repo = FakeLauncherAppsRepository(
            listOf(
                LauncherAppEntry("com.example.blocked", "BlockedActivity", "Blocked"),
                LauncherAppEntry("com.example.allowed", "AllowedActivity", "Allowed"),
            ),
        )
        val policy = LambdaPolicy { packageName ->
            when (packageName) {
                "com.example.blocked" -> BlockDecision(true, BlockReason.FOCUS_SESSION)
                else -> BlockDecision(false, null)
            }
        }
        val navigator = RecordingBlockedNavigator()
        val starter = RecordingLauncherStarter()
        val viewModel = HomeViewModel(
            appsRepository = repo,
            appBlockPolicy = policy,
            blockedAppNavigator = navigator,
            launcherStarter = starter,
            ioDispatcher = mainDispatcherRule.dispatcher,
        )

        viewModel.loadApps()
        advanceUntilIdle()

        val apps = viewModel.uiState.value.apps
        assertEquals(2, apps.size)
        assertTrue(apps[0].blocked)
        assertEquals(BlockReason.FOCUS_SESSION, apps[0].blockReason)
        assertFalse(apps[1].blocked)
        assertNull(apps[1].blockReason)
    }

    @Test
    fun `clicking blocked app opens blocked navigator and does not launch`() {
        val navigator = RecordingBlockedNavigator()
        val starter = RecordingLauncherStarter()
        val viewModel = HomeViewModel(
            appsRepository = FakeLauncherAppsRepository(emptyList()),
            appBlockPolicy = LambdaPolicy { BlockDecision(true, BlockReason.BLACKOUT_SESSION) },
            blockedAppNavigator = navigator,
            launcherStarter = starter,
            ioDispatcher = mainDispatcherRule.dispatcher,
        )

        viewModel.onAppClicked(
            LaunchableAppItem(
                packageName = "com.example.blocked",
                activityName = "MainActivity",
                label = "Blocked",
                blocked = true,
                blockReason = BlockReason.BLACKOUT_SESSION,
            ),
        )

        assertEquals("com.example.blocked", navigator.lastPackageName)
        assertEquals(BlockReason.BLACKOUT_SESSION, navigator.lastReason)
        assertNull(starter.lastPackageName)
    }

    @Test
    fun `clicking allowed app launches normally`() {
        val navigator = RecordingBlockedNavigator()
        val starter = RecordingLauncherStarter()
        val viewModel = HomeViewModel(
            appsRepository = FakeLauncherAppsRepository(emptyList()),
            appBlockPolicy = LambdaPolicy { BlockDecision(false, null) },
            blockedAppNavigator = navigator,
            launcherStarter = starter,
            ioDispatcher = mainDispatcherRule.dispatcher,
        )

        viewModel.onAppClicked(
            LaunchableAppItem(
                packageName = "com.example.allowed",
                activityName = "MainActivity",
                label = "Allowed",
                blocked = false,
                blockReason = null,
            ),
        )

        assertEquals("com.example.allowed", starter.lastPackageName)
        assertEquals("MainActivity", starter.lastActivityName)
        assertNull(navigator.lastPackageName)
    }

    @Test
    fun `launcher revalidates just before launch`() {
        val policy = SequencedPolicy(
            mapOf(
                "com.example.allowed" to ArrayDeque(
                    listOf(
                        BlockDecision(false, null),
                        BlockDecision(true, BlockReason.CLASSIC_LIMIT_REACHED),
                    ),
                ),
            ),
        )
        val navigator = RecordingBlockedNavigator()
        val starter = RecordingLauncherStarter()
        val viewModel = HomeViewModel(
            appsRepository = FakeLauncherAppsRepository(emptyList()),
            appBlockPolicy = policy,
            blockedAppNavigator = navigator,
            launcherStarter = starter,
            ioDispatcher = mainDispatcherRule.dispatcher,
        )

        viewModel.onAppClicked(
            LaunchableAppItem(
                packageName = "com.example.allowed",
                activityName = "MainActivity",
                label = "Allowed",
                blocked = false,
                blockReason = null,
            ),
        )

        assertEquals("com.example.allowed", navigator.lastPackageName)
        assertEquals(BlockReason.CLASSIC_LIMIT_REACHED, navigator.lastReason)
        assertNull(starter.lastPackageName)
    }

    private class FakeLauncherAppsRepository(
        private val entries: List<LauncherAppEntry>,
    ) : LauncherAppsRepository {
        override suspend fun getLaunchableApps(): List<LauncherAppEntry> = entries
        override fun registerCallbacks() = Unit
        override fun unregisterCallbacks() = Unit
    }

    private class LambdaPolicy(
        private val evaluator: (String) -> BlockDecision,
    ) : AppBlockPolicy {
        override fun isBlocked(packageName: String): BlockDecision = evaluator(packageName)
    }

    private class SequencedPolicy(
        private val decisions: Map<String, ArrayDeque<BlockDecision>>,
    ) : AppBlockPolicy {
        override fun isBlocked(packageName: String): BlockDecision {
            val queue = decisions[packageName] ?: return BlockDecision(false, null)
            return if (queue.size > 1) queue.removeFirst() else queue.first()
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

    class MainDispatcherRule(
        val dispatcher: TestDispatcher = StandardTestDispatcher(),
    ) : TestWatcher() {
        override fun starting(description: Description) {
            Dispatchers.setMain(dispatcher)
        }

        override fun finished(description: Description) {
            Dispatchers.resetMain()
        }
    }
}
