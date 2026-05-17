package com.wakeapp.ceoos.blocking

import android.content.Context
import android.content.Intent
import com.wakeapp.ceoos.BlockPolicyRepository

class LauncherPackageResolver(
    private val context: Context,
) {
    @Volatile
    private var homePackages: Set<String> = BlockPolicyRepository.homePackages(context)

    @Volatile
    private var defaultLauncherPackage: String? = resolveDefaultLauncher()

    fun refresh() {
        homePackages = BlockPolicyRepository.homePackages(context)
        defaultLauncherPackage = resolveDefaultLauncher()
    }

    fun isLauncherPackage(packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return false
        return homePackages.contains(packageName)
    }

    fun isDefaultLauncher(packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return false
        return packageName == defaultLauncherPackage
    }

    fun currentHomePackages(): Set<String> = homePackages

    private fun resolveDefaultLauncher(): String? {
        return try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
            }
            context.packageManager.resolveActivity(intent, 0)
                ?.activityInfo?.packageName?.trim()
        } catch (_: Exception) {
            null
        }
    }
}
