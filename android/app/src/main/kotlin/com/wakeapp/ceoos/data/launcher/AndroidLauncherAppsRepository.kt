package com.wakeapp.ceoos.data.launcher

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.LauncherApps
import android.os.Process
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Locale

class AndroidLauncherAppsRepository(
    private val context: Context,
    private val packageMonitor: LauncherPackageMonitor? = null,
) : LauncherAppsRepository {
    override suspend fun getLaunchableApps(): List<LauncherAppEntry> = withContext(Dispatchers.Default) {
        val launcherApps = context.getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps
        val launchableApps = linkedMapOf<String, LauncherAppEntry>()

        try {
            launcherApps.getActivityList(null, Process.myUserHandle())
                .forEach { info ->
                    val component = info.componentName ?: return@forEach
                    val packageName = component.packageName.trim()
                    val activityName = component.className.trim()
                    if (packageName.isEmpty() || activityName.isEmpty()) return@forEach
                    val label = info.label?.toString()?.trim().orEmpty().ifEmpty { packageName }
                    val key = "$packageName/$activityName"
                    launchableApps[key] = LauncherAppEntry(
                        packageName = packageName,
                        activityName = activityName,
                        label = label,
                    )
                }
        } catch (_: Exception) {
            context.packageManager.queryIntentActivities(
                Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                },
                0,
            ).forEach { resolveInfo ->
                val activityInfo = resolveInfo.activityInfo ?: return@forEach
                val packageName = activityInfo.packageName?.trim().orEmpty()
                val activityName = activityInfo.name?.trim().orEmpty()
                if (packageName.isEmpty() || activityName.isEmpty()) return@forEach
                val component = ComponentName(packageName, activityName)
                val label = resolveInfo.loadLabel(context.packageManager)?.toString()?.trim()
                    .orEmpty()
                    .ifEmpty { component.packageName }
                val key = "${component.packageName}/${component.className}"
                launchableApps[key] = LauncherAppEntry(
                    packageName = component.packageName,
                    activityName = component.className,
                    label = label,
                )
            }
        }

        launchableApps.values.sortedWith(
            compareBy<LauncherAppEntry> { it.label.lowercase(Locale.getDefault()) }
                .thenBy { it.packageName.lowercase(Locale.getDefault()) },
        )
    }

    override fun registerCallbacks() {
        packageMonitor?.register()
    }

    override fun unregisterCallbacks() {
        packageMonitor?.unregister()
    }
}
