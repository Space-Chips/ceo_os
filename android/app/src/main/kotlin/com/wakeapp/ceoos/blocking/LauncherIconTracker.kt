package com.wakeapp.ceoos.blocking

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Rect
import android.util.TypedValue
import android.view.accessibility.AccessibilityNodeInfo
import java.util.Locale

class LauncherIconTracker(
    private val context: Context,
) {
    private val appIndex = LauncherAppIndex(context)
    private val minIconSizePx = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        40f,
        context.resources.displayMetrics,
    ).toInt()

    fun refreshIndex() {
        appIndex.refresh()
    }

    fun findTargets(root: AccessibilityNodeInfo?): List<LauncherIconTarget> {
        if (root == null) return emptyList()
        val targets = mutableListOf<LauncherIconTarget>()
        val visited = mutableSetOf<Int>()
        val stack = ArrayDeque<Pair<AccessibilityNodeInfo, Int>>()
        stack.add(root to 0)

        while (stack.isNotEmpty()) {
            val (node, depth) = stack.removeLast()
            val identity = System.identityHashCode(node)
            if (!visited.add(identity)) continue
            if (visited.size > 600) break
            if (depth > 12) continue

            val label = extractLabel(node)
            if (label != null) {
                val packageName = appIndex.packageForLabel(label)
                if (packageName != null) {
                    val bounds = Rect()
                    node.getBoundsInScreen(bounds)
                    val resolvedBounds = resolveTapBounds(node, bounds)
                    if (resolvedBounds.width() >= minIconSizePx && resolvedBounds.height() >= minIconSizePx) {
                        targets.add(
                            LauncherIconTarget(
                                packageName = packageName,
                                label = label,
                                bounds = resolvedBounds,
                            ),
                        )
                    }
                }
            }

            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { child ->
                    stack.add(child to depth + 1)
                }
            }
        }

        return targets
    }

    private fun extractLabel(node: AccessibilityNodeInfo): String? {
        val direct = labelFromNode(node)
        val candidate = direct ?: labelFromChildren(node, maxDepth = 2) ?: return null

        val cleaned = normalizeLabel(candidate)
        if (cleaned.isEmpty()) return null
        if (cleaned.length > 40) return null
        if (cleaned.all { it.isDigit() || it == ':' }) return null
        return cleaned
    }

    private fun labelFromNode(node: AccessibilityNodeInfo): String? {
        val raw = node.contentDescription?.toString()?.trim().orEmpty()
        if (raw.isNotEmpty()) return raw
        val fallback = node.text?.toString()?.trim().orEmpty()
        return if (fallback.isNotEmpty()) fallback else null
    }

    private fun labelFromChildren(node: AccessibilityNodeInfo, maxDepth: Int): String? {
        val stack = ArrayDeque<Pair<AccessibilityNodeInfo, Int>>()
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                stack.add(child to 1)
            }
        }
        while (stack.isNotEmpty()) {
            val (child, depth) = stack.removeFirst()
            val label = labelFromNode(child)
            if (!label.isNullOrBlank()) return label
            if (depth < maxDepth) {
                for (i in 0 until child.childCount) {
                    child.getChild(i)?.let { grandChild ->
                        stack.add(grandChild to depth + 1)
                    }
                }
            }
        }
        return null
    }

    private fun resolveTapBounds(node: AccessibilityNodeInfo, initial: Rect): Rect {
        if (initial.width() >= minIconSizePx && initial.height() >= minIconSizePx) {
            return initial
        }
        val parent = node.parent ?: return initial
        val parentBounds = Rect()
        parent.getBoundsInScreen(parentBounds)
        return if (parentBounds.width() >= initial.width() && parentBounds.height() >= initial.height()) {
            parentBounds
        } else {
            initial
        }
    }

    private fun normalizeLabel(raw: String): String {
        val first = raw.split('\n').firstOrNull().orEmpty()
        val trimmed = first.substringBefore(',').trim()
        return trimmed.replace(Regex("\\s+"), " ")
            .lowercase(Locale.getDefault())
            .trim()
    }

    private class LauncherAppIndex(
        private val context: Context,
    ) {
        private val labelToPackages = mutableMapOf<String, MutableList<String>>()
        private var uniqueLabelMap = emptyMap<String, String>()

        init {
            refresh()
        }

        fun refresh() {
            labelToPackages.clear()
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            val results = context.packageManager.queryIntentActivities(intent, PackageManager.GET_META_DATA)
            results.forEach { resolveInfo ->
                val label = resolveInfo.loadLabel(context.packageManager)?.toString()?.trim().orEmpty()
                val pkg = resolveInfo.activityInfo?.packageName?.trim().orEmpty()
                if (label.isEmpty() || pkg.isEmpty()) return@forEach
                val normalized = normalize(label)
                if (normalized.isEmpty()) return@forEach
                labelToPackages.getOrPut(normalized) { mutableListOf() }.add(pkg)
            }
            uniqueLabelMap = labelToPackages
                .filterValues { it.size == 1 }
                .mapValues { it.value.first() }
        }

        fun packageForLabel(label: String): String? {
            return uniqueLabelMap[label.lowercase(Locale.getDefault())]
        }

        private fun normalize(raw: String): String {
            return raw.replace(Regex("\\s+"), " ")
                .lowercase(Locale.getDefault())
                .trim()
        }
    }
}
