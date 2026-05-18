package com.wakeapp.ceoos

import android.accessibilityservice.AccessibilityService
import android.content.SharedPreferences
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

open class WakeAccessibilityService : AccessibilityService() {
    private lateinit var foregroundAppDetector: ForegroundAppDetector
    private lateinit var appBlockEngine: AppBlockEngine
    private lateinit var browserBlockCoordinator: BrowserBlockCoordinator
    private lateinit var gateLauncher: GateLauncher
    private lateinit var blockingOverlay: BlockingOverlay

    // Background scope for non-critical I/O (daily-limit accounting).
    // SupervisorJob ensures one failed child doesn't cancel the whole scope.
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    @Volatile
    private var cachedPolicyState: BlockPolicyState? = null

    @Volatile
    private var pendingPolicyRefresh: Boolean = true

    @Volatile
    private var policyRevision: Long = 0L

    private val decisionCache = mutableMapOf<String, BlockDecision>()

    @Volatile
    private var lastForegroundPackage: String? = null

    @Volatile
    private var lastEventAtMillis: Long = 0L

    @Volatile
    private var lastUsageRefreshAtMillis: Long = 0L

    @Volatile
    private var lastUsageRefreshPackage: String? = null

    private var prefsListener: SharedPreferences.OnSharedPreferenceChangeListener? = null

    private val observedPolicyKeys = setOf(
        "focus_shield_active",
        "ceo_shield_active",
        "classic_shield_active",
        "classic_pause_shield_active",
        "classic_daily_limit_exceeded_packages",
        "classic_daily_limit_exceeded_websites",
        "flutter.active_block_list",
        "classic_block_list",
        "classic_pause_block_list",
        "blackout_allowed_packages",
    )

    companion object {
        @Volatile
        private var instance: WakeAccessibilityService? = null

        fun onBlockGateHidden() {
            instance?.gateLauncher?.onGateHidden()
        }

        fun onBlockGateVisible() {
            instance?.blockingOverlay?.hide()
        }

        fun navigateBackFromBlockGate() {
            instance?.performGlobalAction(GLOBAL_ACTION_BACK)
        }

        fun requestImmediateEvaluation() {
            instance?.evaluateCurrentState()
        }

        fun debugSnapshot(): Map<String, Any?> = BlockingLogger.snapshot()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        foregroundAppDetector = ForegroundAppDetector(packageName)
        browserBlockCoordinator = BrowserBlockCoordinator()
        appBlockEngine = AppBlockEngine(browserBlockCoordinator)
        gateLauncher = GateLauncher()
        blockingOverlay = BlockingOverlay(this)
        registerPolicyListener()
        evaluateCurrentState()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (
            event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED
        ) return

        val startedAt = System.currentTimeMillis()
        val eventPackage = event.packageName?.toString()?.trim()
        val isBrowser = foregroundAppDetector.isBrowserPackage(eventPackage)
        if (event.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED && !isBrowser) {
            return
        }
        val snapshot = foregroundAppDetector.createSnapshot(
            event,
            if (isBrowser) rootInActiveWindow else null,
        )
        val packageName = snapshot.packageName
        if (packageName != null) {
            // Ignore rapid non-state changes for the same package to minimize latency.
            val lastPackage = lastForegroundPackage
            val lastAt = lastEventAtMillis
            if (
                lastPackage == packageName &&
                event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
                startedAt - lastAt < 220L
            ) {
                return
            }
            lastForegroundPackage = packageName
            lastEventAtMillis = startedAt
        }
        handleSnapshot(snapshot, startedAt)
    }

    override fun onInterrupt() = Unit

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        prefsListener?.let {
            getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                .unregisterOnSharedPreferenceChangeListener(it)
        }
        serviceScope.cancel()
        gateLauncher.dismiss(this)
    }

    private fun evaluateCurrentState() {
        val root = rootInActiveWindow ?: return
        val syntheticEvent = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOWS_CHANGED).apply {
            packageName = root.packageName
            className = root.className
        }
        try {
            val snapshot = foregroundAppDetector.createSnapshot(syntheticEvent, root)
            handleSnapshot(snapshot, System.currentTimeMillis())
        } finally {
            syntheticEvent.recycle()
        }
    }

    private fun handleSnapshot(snapshot: ForegroundSnapshot, startedAt: Long) {
        if (foregroundAppDetector.isGateSnapshot(snapshot)) {
            return
        }

        // --- CRITICAL PATH: use cached policy state for O(1) lookup ---
        val policyState = getPolicyStateFast()
        val packageName = snapshot.packageName
        val decision = if (!snapshot.isBrowser && !packageName.isNullOrBlank()) {
            decisionCache[packageName] ?: run {
                val computed = appBlockEngine.evaluate(
                    snapshot = snapshot,
                    state = policyState,
                    isGateVisible = BlockGateActivity.isVisible,
                )
                if (computed is BlockDecision.BlockApp || computed is BlockDecision.Allow) {
                    decisionCache[packageName] = computed
                }
                computed
            }
        } else {
            appBlockEngine.evaluate(
                snapshot = snapshot,
                state = policyState,
                isGateVisible = BlockGateActivity.isVisible,
            )
        }

        val gateLaunched = when (decision) {
            BlockDecision.Allow -> {
                blockingOverlay.hide()
                gateLauncher.dismiss(this)
                false
            }
            BlockDecision.IgnoreTransient -> false
            is BlockDecision.BlockApp -> {
                blockingOverlay.show()
                val launched = gateLauncher.launch(this, decision)
                if (!launched) {
                    blockingOverlay.hide()
                }
                launched
            }
            is BlockDecision.BlockUrl -> {
                blockingOverlay.show()
                val launched = browserBlockCoordinator.handleBlockedUrl(this, decision, gateLauncher)
                if (!launched) {
                    blockingOverlay.hide()
                }
                launched
            }
        }

        // --- NON-CRITICAL: daily-limit accounting runs in background ---
        // This calls UsageStatsManager (slow disk I/O) and must NOT block
        // the gate from appearing. It writes back exceeded-package lists
        // to SharedPreferences, which are read on the next event cycle.
        val now = System.currentTimeMillis()
        val lastRefreshAt = lastUsageRefreshAtMillis
        val lastRefreshPackage = lastUsageRefreshPackage
        val refreshCooldownMillis = 1200L
        if (snapshot.packageName != null &&
            (snapshot.packageName != lastRefreshPackage || now - lastRefreshAt >= refreshCooldownMillis)
        ) {
            lastUsageRefreshAtMillis = now
            lastUsageRefreshPackage = snapshot.packageName
            serviceScope.launch {
                try {
                    BlockPolicyRepository.refreshDailyLimitState(this@WakeAccessibilityService, snapshot)
                    pendingPolicyRefresh = true
                } catch (e: Exception) {
                    Log.w("WakeAccessibilityService", "refreshDailyLimitState failed", e)
                }
            }
        }

        if (gateLaunched || decision !is BlockDecision.Allow) {
            BlockingLogger.record(
                eventType = snapshot.eventType,
                packageName = snapshot.packageName,
                className = snapshot.className,
                detectedUrl = snapshot.detectedBrowserUrl,
