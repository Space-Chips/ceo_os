package com.wakeapp.ceoos

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.SharedPreferences
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * App blocking entrypoint on Android.
 *
 * Design goals:
 * - Single responsibility: decide block/allow from a foreground package snapshot.
 * - No multi-layer interception / overlays / polling loops.
 * - Fast path + debounce to avoid relaunch loops.
 */
open class BlockingAccessibilityService : AccessibilityService() {
    private lateinit var foregroundAppDetector: ForegroundAppDetector
    private lateinit var appBlockEngine: AppBlockEngine
    private lateinit var appBlockingOverlay: AppBlockingOverlay

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    @Volatile
    private var cachedPolicyState: BlockPolicyState? = null

    @Volatile
    private var pendingPolicyRefresh: Boolean = true

    private var homePackagesCache: Set<String> = emptySet()

    private var prefsListener: SharedPreferences.OnSharedPreferenceChangeListener? = null

    @Volatile
    private var lastForegroundPackage: String? = null

    @Volatile
    private var lastEventAtElapsedMillis: Long = 0L

    @Volatile
    private var gateShownForPackage: String? = null

    private val observedPolicyKeys = setOf(
        "focus_shield_active",
        "ceo_shield_active",
        "classic_shield_active",
        "classic_pause_shield_active",
        "classic_daily_limit_exceeded_packages",
        "flutter.active_block_list",
        "classic_block_list",
        "classic_pause_block_list",
        "blackout_allowed_packages",
    )

    companion object {
        @Volatile
        private var instance: BlockingAccessibilityService? = null

        fun onBlockGateHidden() {
            instance?.onGateHiddenByActivity()
        }

        fun onBlockGateVisible() = Unit

        fun navigateBackFromBlockGate() {
            instance?.performGlobalAction(GLOBAL_ACTION_BACK)
        }

        fun navigateHomeFromBlockGate() {
            instance?.performGlobalAction(GLOBAL_ACTION_HOME)
        }

        fun navigateHomeFromBlockGate(
            blockType: String?,
            browserPackage: String?,
            blockedDomain: String?,
        ) {
            // App blocking only (for now): always return home.
            instance?.performGlobalAction(GLOBAL_ACTION_HOME)
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
        appBlockEngine = AppBlockEngine()
        appBlockingOverlay = AppBlockingOverlay(this, serviceScope)
        homePackagesCache = BlockPolicyRepository.homePackages(this)
        registerPolicyListener()
        evaluateCurrentState()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (
            event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) return

        val now = SystemClock.elapsedRealtime()
        val eventPackage = event.packageName?.toString()?.trim().orEmpty()
        if (eventPackage.isEmpty()) return

        // Debounce: avoid spinning on content changes for the same foreground package.
        val lastPackage = lastForegroundPackage
        val lastAt = lastEventAtElapsedMillis
        if (lastPackage == eventPackage && event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            if (now - lastAt < 90L) return
        }
        lastForegroundPackage = eventPackage
        lastEventAtElapsedMillis = now

        val snapshot = foregroundAppDetector.createSnapshot(
            event = event,
            root = null,
            includeBrowserSignals = false,
        )
        handleSnapshot(snapshot)
    }

    override fun onInterrupt() = Unit

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        prefsListener?.let {
            getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                .unregisterOnSharedPreferenceChangeListener(it)
        }
        prefsListener = null
        serviceScope.cancel()
        appBlockingOverlay.detach()
        gateShownForPackage = null
    }

    private fun handleSnapshot(snapshot: ForegroundSnapshot) {
        val policy = readPolicyState() ?: return
        val isGateVisible = false
        val decision = appBlockEngine.evaluate(
            snapshot = snapshot,
            state = policy,
            isGateVisible = isGateVisible,
        )

        when (decision) {
            is BlockDecision.BlockApp -> showOverlayForBlockedApp(decision)
            else -> {
                appBlockingOverlay.hide()
            }
        }
    }

    private fun showOverlayForBlockedApp(decision: BlockDecision.BlockApp) {
        val blockedPackage = decision.packageName.trim()
        if (blockedPackage.isEmpty()) return

        gateShownForPackage = blockedPackage
        appBlockingOverlay.show(decision)
    }

    private fun onGateHiddenByActivity() {
        gateShownForPackage = null
        evaluateCurrentState()
    }

    private fun evaluateCurrentState() {
        val root = rootInActiveWindow ?: return
        val syntheticEvent = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOWS_CHANGED).apply {
            packageName = root.packageName
            className = root.className
        }
        try {
            val snapshot = foregroundAppDetector.createSnapshot(
                event = syntheticEvent,
                root = root,
                includeBrowserSignals = false,
            )
            handleSnapshot(snapshot)
        } finally {
            syntheticEvent.recycle()
        }
    }

    private fun readPolicyState(): BlockPolicyState? {
        if (pendingPolicyRefresh || cachedPolicyState == null) {
            cachedPolicyState = BlockPolicyRepository.readState(this, homePackagesCache)
            pendingPolicyRefresh = false
        }
        return cachedPolicyState
    }

    private fun registerPolicyListener() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key != null && observedPolicyKeys.contains(key)) {
                pendingPolicyRefresh = true
                serviceScope.launch { evaluateCurrentState() }
            }
        }
        prefs.registerOnSharedPreferenceChangeListener(listener)
        prefsListener = listener
    }
}
