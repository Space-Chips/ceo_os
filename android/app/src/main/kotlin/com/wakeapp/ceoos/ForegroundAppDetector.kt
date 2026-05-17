package com.wakeapp.ceoos

import android.graphics.Rect
import android.os.Build
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.util.Locale

data class ForegroundSnapshot(
    val packageName: String?,
    val className: String?,
    val eventType: Int,
    val detectedBrowserUrl: String? = null,
    val isBrowser: Boolean = false,
    val browserToolbarBottomPx: Int? = null,
    val browserAddressBarFocused: Boolean = false,
)

class ForegroundAppDetector(
    private val wakePackageName: String,
) {
    companion object {
        private data class BrowserProfile(
            val packageName: String,
            val exactViewIds: Set<String>,
            val viewIdHints: Set<String>,
            val allowTopToolbarTextFallback: Boolean = false,
        )

        private val browserProfiles = listOf(
            BrowserProfile(
                packageName = "com.android.chrome",
                exactViewIds = setOf(
                    "com.android.chrome:id/url_bar",
                    "com.android.chrome:id/search_box",
                    "com.android.chrome:id/search_src_text",
                    "com.android.chrome:id/location_bar",
                ),
                viewIdHints = setOf(
                    ":id/url_bar",
                    ":id/location_bar",
                    ":id/search_box",
                    ":id/search_src_text",
                ),
            ),
            BrowserProfile(
                packageName = "com.brave.browser",
                exactViewIds = setOf(
                    "com.brave.browser:id/url_bar",
                    "com.brave.browser:id/search_box",
                    "com.brave.browser:id/search_src_text",
                    "com.brave.browser:id/location_bar",
                ),
                viewIdHints = setOf(
                    ":id/url_bar",
                    ":id/location_bar",
                    ":id/search_box",
                    ":id/search_src_text",
                ),
            ),
            BrowserProfile(
                packageName = "com.huawei.browser",
                exactViewIds = setOf(
                    "com.huawei.browser:id/url_bar",
                    "com.huawei.browser:id/address_bar",
                    "com.huawei.browser:id/url",
                    "com.huawei.browser:id/address",
                    "com.huawei.browser:id/search_src_text",
                ),
                viewIdHints = setOf(
                    ":id/url_bar",
                    ":id/address_bar",
                    ":id/url",
                    ":id/address",
                    ":id/search_src_text",
                ),
            ),
            BrowserProfile(
                packageName = "com.google.android.googlequicksearchbox",
                exactViewIds = setOf(
                    "com.google.android.googlequicksearchbox:id/url_bar",
                    "com.google.android.googlequicksearchbox:id/location_bar",
                    "com.google.android.googlequicksearchbox:id/googleapp_url_bar",
                    "com.google.android.googlequicksearchbox:id/web_address_bar",
                    "com.google.android.googlequicksearchbox:id/search_src_text",
                    "com.google.android.googlequicksearchbox:id/search_box",
                    "com.google.android.googlequicksearchbox:id/omnibox_text",
                ),
                viewIdHints = setOf(
                    ":id/url_bar",
                    ":id/location_bar",
                    ":id/googleapp_url_bar",
                    ":id/web_address_bar",
                    ":id/search_src_text",
                    ":id/search_box",
                    ":id/omnibox",
                    ":id/address",
                ),
                allowTopToolbarTextFallback = true,
            ),
        )

        private val packagesToProfile = buildMap<String, BrowserProfile> {
            browserProfiles.forEach { profile ->
                put(profile.packageName, profile)
            }
        }

        private const val retainedDomainWindowMillis = 1_200L
    }

    private data class RecentDetectedDomain(
        val domain: String,
        val atElapsedMillis: Long,
    )

    private val recentDetectedDomainsByPackage = mutableMapOf<String, RecentDetectedDomain>()

    fun isBrowserPackage(packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return false
        return packagesToProfile.containsKey(packageName)
    }

    fun createSnapshot(
        event: AccessibilityEvent,
        root: AccessibilityNodeInfo?,
        includeBrowserSignals: Boolean = true,
    ): ForegroundSnapshot {
        val packageName = root?.packageName?.toString()?.trim()?.ifEmpty { null }
            ?: event.packageName?.toString()?.trim()?.ifEmpty { null }
        val className = event.className?.toString()?.trim()?.ifEmpty { null }
        if (!includeBrowserSignals) {
            return ForegroundSnapshot(
                packageName = packageName,
                className = className,
                eventType = event.eventType,
                detectedBrowserUrl = null,
                isBrowser = false,
                browserToolbarBottomPx = null,
                browserAddressBarFocused = false,
            )
        }

        val isBrowser = isBrowserPackage(packageName)
        val detectedNow = if (isBrowser) detectBrowserUrl(event, root, packageName) else null
        val detectedUrl = if (isBrowser) resolveDetectedDomain(packageName, detectedNow) else null
        val toolbarBottomPx = if (isBrowser) detectBrowserToolbarBottom(root, packageName) else null
        val addressBarFocused = if (isBrowser) detectAddressBarFocused(event, root, packageName) else false

        return ForegroundSnapshot(
            packageName = packageName,
            className = className,
            eventType = event.eventType,
            detectedBrowserUrl = detectedUrl,
            isBrowser = isBrowser,
            browserToolbarBottomPx = toolbarBottomPx,
            browserAddressBarFocused = addressBarFocused,
        )
    }

    fun isGateSnapshot(snapshot: ForegroundSnapshot): Boolean {
        return snapshot.packageName == wakePackageName &&
            (snapshot.className?.contains("BlockGateActivity") == true)
    }

    fun clearRecentDomain(packageName: String?) {
        val browserPackage = packageName?.trim().orEmpty()
        if (browserPackage.isEmpty()) return
        recentDetectedDomainsByPackage.remove(browserPackage)
    }

    private fun detectBrowserUrl(
        event: AccessibilityEvent,
        root: AccessibilityNodeInfo?,
        packageName: String?,
    ): String? {
        val profile = packageName?.let { packagesToProfile[it] } ?: return null
        event.source?.let { source ->
            extractFromAddressNode(source, profile)?.let { return it }
        }

        val fromAddressField = findAddressBarDomain(root, profile)
        if (fromAddressField != null) return fromAddressField
        if (!profile.allowTopToolbarTextFallback) return null
        return findTopToolbarDomainFallback(root)
    }

    private fun detectBrowserToolbarBottom(
        root: AccessibilityNodeInfo?,
        packageName: String?,
    ): Int? {
        val profile = packageName?.let { packagesToProfile[it] } ?: return null
        val bounds = findBestAddressBarBounds(root, profile) ?: return null
        return if (bounds.bottom > 0) bounds.bottom else null
    }

    private fun detectAddressBarFocused(
        event: AccessibilityEvent,
        root: AccessibilityNodeInfo?,
        packageName: String?,
    ): Boolean {
        val profile = packageName?.let { packagesToProfile[it] } ?: return false
        event.source?.let { source ->
            if (isAddressBarNode(source, profile) && (source.isFocused || source.isAccessibilityFocused)) {
                return true
            }
        }
        return isAnyAddressBarFocused(root, profile)
    }

    private fun resolveDetectedDomain(packageName: String?, detectedNow: String?): String? {
        val browserPackage = packageName?.trim().orEmpty()
        if (browserPackage.isEmpty()) return detectedNow

        val now = SystemClock.elapsedRealtime()
        if (detectedNow != null) {
            recentDetectedDomainsByPackage[browserPackage] = RecentDetectedDomain(
                domain = detectedNow,
                atElapsedMillis = now,
            )
            return detectedNow
        }

        val recent = recentDetectedDomainsByPackage[browserPackage] ?: return null
        if (now - recent.atElapsedMillis <= retainedDomainWindowMillis) {
            return recent.domain
        }
        recentDetectedDomainsByPackage.remove(browserPackage)
        return null
    }

    private fun findAddressBarDomain(
        root: AccessibilityNodeInfo?,
        profile: BrowserProfile,
    ): String? {
        if (root == null) return null
        val visited = mutableSetOf<Int>()
        var bestDomain: String? = null
        var bestScore = Int.MIN_VALUE

        fun visit(node: AccessibilityNodeInfo?, depth: Int) {
            if (node == null || depth > 10) return
            val identity = System.identityHashCode(node)
            if (!visited.add(identity) || visited.size > 420) return

            val extracted = extractFromAddressNode(node, profile)
            if (extracted != null) {
                val score = scoreAddressNode(node, profile)
                if (score > bestScore) {
                    bestScore = score
                    bestDomain = extracted
                }
            }

            for (index in 0 until node.childCount) {
                visit(node.getChild(index), depth + 1)
            }
        }

        visit(root, 0)
        return bestDomain
    }

    private fun findBestAddressBarBounds(
        root: AccessibilityNodeInfo?,
        profile: BrowserProfile,
    ): Rect? {
        if (root == null) return null
        val visited = mutableSetOf<Int>()
        var bestBounds: Rect? = null
        var bestScore = Int.MIN_VALUE

        fun visit(node: AccessibilityNodeInfo?, depth: Int) {
            if (node == null || depth > 10) return
            val identity = System.identityHashCode(node)
            if (!visited.add(identity) || visited.size > 420) return

            if (isAddressBarNode(node, profile)) {
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                if (isLikelyToolbarAddressField(bounds)) {
                    val score = scoreAddressNode(node, profile)
                    if (score > bestScore) {
                        bestScore = score
                        bestBounds = Rect(bounds)
                    }
                }
            }

            for (index in 0 until node.childCount) {
                visit(node.getChild(index), depth + 1)
            }
        }

        visit(root, 0)
        return bestBounds
    }

    private fun isAnyAddressBarFocused(
        root: AccessibilityNodeInfo?,
        profile: BrowserProfile,
    ): Boolean {
        if (root == null) return false
        val visited = mutableSetOf<Int>()
        var focused = false

        fun visit(node: AccessibilityNodeInfo?, depth: Int) {
            if (node == null || depth > 10 || focused) return
            val identity = System.identityHashCode(node)
            if (!visited.add(identity) || visited.size > 420) return

            if (isAddressBarNode(node, profile) && (node.isFocused || node.isAccessibilityFocused)) {
                focused = true
                return
            }

            for (index in 0 until node.childCount) {
                visit(node.getChild(index), depth + 1)
            }
        }

        visit(root, 0)
        return focused
    }

    private fun isAddressBarNode(
        node: AccessibilityNodeInfo,
        profile: BrowserProfile,
    ): Boolean {
        val viewId = node.viewIdResourceName?.lowercase(Locale.US).orEmpty()
        if (viewId.isEmpty()) return false
        if (profile.exactViewIds.contains(viewId)) return true
        return profile.viewIdHints.any { viewId.contains(it) }
    }

    private fun isLikelyToolbarAddressField(bounds: Rect): Boolean {
        if (bounds.isEmpty) return false
        if (bounds.top < 0) return false
        if (bounds.width() <= 0 || bounds.height() <= 0) return false
        if (bounds.width() < bounds.height() * 2) return false
        // Restrict to the upper area to avoid page-content false positives.
        if (bounds.top > 520) return false
        return true
    }

    private fun candidateTexts(node: AccessibilityNodeInfo): Sequence<String> = sequence {
        node.text?.toString()?.let { yield(it) }
        node.contentDescription?.toString()?.let { yield(it) }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            node.hintText?.toString()?.let { yield(it) }
        }
    }

    private fun scoreAddressNode(
        node: AccessibilityNodeInfo,
        profile: BrowserProfile,
    ): Int {
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        val viewId = node.viewIdResourceName?.lowercase(Locale.US).orEmpty()
        val hintScore = when {
            profile.exactViewIds.contains(viewId) -> 2_000
            else -> {
                val hint = profile.viewIdHints.maxOfOrNull { candidate ->
                    if (viewId.contains(candidate)) candidate.length else 0
                } ?: 0
                hint * 100
            }
        }
        val widthScore = bounds.width().coerceAtLeast(0)
        val topBias = (1_600 - bounds.top).coerceAtLeast(0)
        return hintScore + widthScore + topBias
    }

    private fun findTopToolbarDomainFallback(root: AccessibilityNodeInfo?): String? {
        if (root == null) return null
        val visited = mutableSetOf<Int>()
        var bestDomain: String? = null
        var bestScore = Int.MIN_VALUE

        fun visit(node: AccessibilityNodeInfo?, depth: Int) {
            if (node == null || depth > 9) return
            val identity = System.identityHashCode(node)
            if (!visited.add(identity) || visited.size > 360) return

            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            val className = node.className?.toString()?.lowercase(Locale.US).orEmpty()
            val canContainAddressText =
                className.contains("edittext") || className.contains("textview")
            if (canContainAddressText && isLikelyToolbarAddressField(bounds)) {
                candidateTexts(node).forEach { raw ->
                    BrowserBlockCoordinator.normalizeDomainToken(raw)?.let { domain ->
                        val score = bounds.width().coerceAtLeast(0) + (1_600 - bounds.top).coerceAtLeast(0)
                        if (score > bestScore) {
                            bestScore = score
                            bestDomain = domain
                        }
                    }
                }
            }

            for (index in 0 until node.childCount) {
                visit(node.getChild(index), depth + 1)
            }
        }

        visit(root, 0)
        return bestDomain
    }

    private fun extractFromAddressNode(
        node: AccessibilityNodeInfo,
        profile: BrowserProfile,
    ): String? {
        if (!isAddressBarNode(node, profile)) return null
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        if (!isLikelyToolbarAddressField(bounds)) return null
        candidateTexts(node).forEach { raw ->
            BrowserBlockCoordinator.normalizeDomainToken(raw)?.let { return it }
        }
        return null
    }
}
