package com.wakeapp.ceoos.data.launcher

import android.content.Context
import android.content.pm.LauncherApps
import android.os.Handler
import android.os.Looper
import android.os.UserHandle

class LauncherPackageMonitor(
    context: Context,
    private val onPackagesChanged: () -> Unit,
) {
    private val launcherApps =
        context.getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps

    private val callback = object : LauncherApps.Callback() {
        override fun onPackageRemoved(packageName: String?, user: UserHandle?) = notifyChanged()
        override fun onPackageAdded(packageName: String?, user: UserHandle?) = notifyChanged()
        override fun onPackageChanged(packageName: String?, user: UserHandle?) = notifyChanged()
        override fun onPackagesAvailable(
            packageNames: Array<out String>?,
            user: UserHandle?,
            replacing: Boolean,
        ) = notifyChanged()

        override fun onPackagesUnavailable(
            packageNames: Array<out String>?,
            user: UserHandle?,
            replacing: Boolean,
        ) = notifyChanged()

        override fun onPackagesSuspended(packageNames: Array<out String>?, user: UserHandle?) = notifyChanged()
        override fun onPackagesUnsuspended(packageNames: Array<out String>?, user: UserHandle?) = notifyChanged()
    }

    private var registered = false

    fun register() {
        if (registered) return
        launcherApps.registerCallback(callback, Handler(Looper.getMainLooper()))
        registered = true
    }

    fun unregister() {
        if (!registered) return
        launcherApps.unregisterCallback(callback)
        registered = false
    }

    private fun notifyChanged() {
        onPackagesChanged()
    }
}
