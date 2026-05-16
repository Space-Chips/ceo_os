package com.wakeapp.ceoos

enum class ActiveMode {
    NONE,
    FOCUS,
    BLACKOUT,
    CLASSIC,
    CLASSIC_PAUSE,
    DAILY_LIMIT,
}

object ModeResolver {
    private val systemExemptPackages = setOf(
        "android",
        "com.android.systemui",
        "com.google.android.permissioncontroller",
        "com.android.permissioncontroller",
        "com.google.android.packageinstaller",
        "com.android.packageinstaller",
    )

    fun resolveCurrentMode(state: BlockPolicyState): ActiveMode {
        return when {
            state.blackoutEnabled -> ActiveMode.BLACKOUT
            state.focusEnabled -> ActiveMode.FOCUS
            state.classicPauseEnabled -> ActiveMode.CLASSIC_PAUSE
            state.classicEnabled -> ActiveMode.CLASSIC
            state.exceededPackages.isNotEmpty() || state.exceededDomains.isNotEmpty() -> ActiveMode.DAILY_LIMIT
            else -> ActiveMode.NONE
        }
    }

    fun isSystemExemptPackage(packageName: String?, state: BlockPolicyState): Boolean {
        if (packageName.isNullOrBlank()) return true
        if (packageName == state.wakePackageName) return true
        if (state.homePackages.contains(packageName)) return true
        if (systemExemptPackages.contains(packageName)) return true
        return packageName.startsWith("com.google.android.inputmethod") ||
            packageName.startsWith("com.android.inputmethod")
    }
}
