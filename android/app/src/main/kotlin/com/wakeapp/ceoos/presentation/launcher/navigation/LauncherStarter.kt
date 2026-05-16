package com.wakeapp.ceoos.presentation.launcher.navigation

import android.content.ComponentName
import android.content.Context
import android.content.Intent

interface LauncherStarter {
    fun start(packageName: String, activityName: String)
}

class AndroidLauncherStarter(
    private val context: Context,
) : LauncherStarter {
    override fun start(packageName: String, activityName: String) {
        val explicitIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
            component = ComponentName(packageName, activityName)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED,
            )
        }

        val fallbackIntent = context.packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
        }

        context.startActivity(fallbackIntent ?: explicitIntent)
    }
}
