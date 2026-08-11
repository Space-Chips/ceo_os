package com.wakeapp.ceoos

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Telephony
import android.telecom.TelecomManager
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.Locale

data class BlockPolicyState(
    val currentMode: ActiveMode,
    val focusEnabled: Boolean,
    val blackoutEnabled: Boolean,
    val classicEnabled: Boolean,
    val classicPauseEnabled: Boolean,
    val focusBlockedPackages: Set<String>,
    val classicBlockedPackages: Set<String>,
    val classicBlockedDomains: Set<String>,
    val classicPauseBlockedPackages: Set<String>,
    val classicPauseBlockedDomains: Set<String>,
    val exceededPackages: Set<String>,
    val exceededDomains: Set<String>,
    val blockedPackages: Set<String>,
    val blockedDomains: Set<String>,
    val blackoutAllowedPackages: Set<String>,
    val homePackages: Set<String>,
    val wakePackageName: String,
)

object BlockPolicyRepository {
    private const val prefsName = "FlutterSharedPreferences"
    private const val focusBlockListKey = "flutter.active_block_list"
    private const val classicBlockListKey = "classic_block_list"
    private const val classicPauseBlockListKey = "classic_pause_block_list"
    private const val dailyLimitConfigKey = "classic_daily_limit_config"
    private const val exceededPackagesKey = "classic_daily_limit_exceeded_packages"
    private const val exceededWebsitesKey = "classic_daily_limit_exceeded_websites"
    private const val websiteUsageDayKeyPref = "classic_daily_limit_website_usage_day"
    private const val websiteUsageMillisKeyPref = "classic_daily_limit_website_usage_millis"
    private const val blackoutAllowedPackagesKey = "blackout_allowed_packages"

    @Volatile
    private var lastTrackedPackageName: String? = null

    @Volatile
    private var lastTrackedDomain: String? = null

    @Volatile
    private var lastTrackedAtMillis: Long = 0L

    fun getCurrentMode(context: Context): ActiveMode {
        return readState(context, homePackages(context)).currentMode
    }

    fun getBlockedPackages(context: Context): Set<String> {
        return readState(context, homePackages(context)).blockedPackages
    }

    fun getAllowedPackagesForBlackout(context: Context): Set<String> {
        return readState(context, homePackages(context)).blackoutAllowedPackages
    }

    fun getBlockedDomains(context: Context): Set<String> {
        return readState(context, homePackages(context)).blockedDomains
    }

    fun updateFocusSelection(
        context: Context,
        packages: List<String>,
        categories: List<String> = emptyList(),
    ) {
        val payload = JSONObject().apply {
            put("blocked_package_names", JSONArray(packages))
            put("blocked_categories", JSONArray(categories))
        }
        prefs(context).edit()
            .putString(focusBlockListKey, payload.toString())
            .apply()
    }

    fun updateClassicShieldConfig(
        context: Context,
        packages: List<String>,
        websites: List<String>,
    ) {
        val payload = JSONObject().apply {
            put("blocked_package_names", JSONArray(packages))
            put("blocked_websites", JSONArray(websites))
        }
        prefs(context).edit()
            .putString(classicBlockListKey, payload.toString())
            .apply()
    }

    fun updateClassicPauseConfig(
        context: Context,
        packages: List<String>,
        websites: List<String>,
    ) {
        val payload = JSONObject().apply {
            put("blocked_package_names", JSONArray(packages))
            put("blocked_websites", JSONArray(websites))
        }
        prefs(context).edit()
            .putString(classicPauseBlockListKey, payload.toString())
            .apply()
    }

    fun updateBlackoutAllowlist(
        context: Context,
        packages: List<String>,
    ) {
        val payload = JSONArray()
        packages.map { it.trim() }.filter { it.isNotEmpty() }.forEach(payload::put)
        prefs(context).edit()
            .putString(blackoutAllowedPackagesKey, payload.toString())
            .apply()
    }

    fun setFocusShieldActive(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean("focus_shield_active", enabled).apply()
    }

    fun setClassicShieldActive(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean("classic_shield_active", enabled).apply()
    }

    fun setClassicPauseShieldActive(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean("classic_pause_shield_active", enabled).apply()
    }

    fun setCeoShieldActive(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean("ceo_shield_active", enabled).apply()
    }

    fun stopShielding(context: Context) {
        prefs(context).edit()
            .putBoolean("focus_shield_active", false)
            .putBoolean("ceo_shield_active", false)
            .apply()
    }

    fun readState(context: Context, homePackages: Set<String>): BlockPolicyState {
        val preferences = prefs(context)
        val focusEnabled = preferences.getBoolean("focus_shield_active", false)
        val blackoutEnabled = preferences.getBoolean("ceo_shield_active", false)
        val classicEnabled = preferences.getBoolean("classic_shield_active", false)
        val classicPauseEnabled = preferences.getBoolean("classic_pause_shield_active", false)

        val focusBlockedPackages = parsePackageArray(
            preferences.getString(focusBlockListKey, null),
            "blocked_package_names",
        )
        val classicBlockedPackages = parsePackageArray(
            preferences.getString(classicBlockListKey, null),
            "blocked_package_names",
        )
        val classicBlockedDomains = parseDomainArray(
            preferences.getString(classicBlockListKey, null),
            "blocked_websites",
        )
        val classicPauseBlockedPackages = parsePackageArray(
            preferences.getString(classicPauseBlockListKey, null),
            "blocked_package_names",
        )
        val classicPauseBlockedDomains = parseDomainArray(
            preferences.getString(classicPauseBlockListKey, null),
            "blocked_websites",
        )
        val exceededPackages = parseStringArray(
            preferences.getString(exceededPackagesKey, null),
        )
        val exceededDomains = parseNormalizedJSONArray(
            preferences.getString(exceededWebsitesKey, null),
        )

        val blockedPackages = linkedSetOf<String>().apply {
            if (classicEnabled) addAll(classicBlockedPackages)
            if (classicPauseEnabled) addAll(classicPauseBlockedPackages)
            addAll(exceededPackages)
        }
        val blockedDomains = linkedSetOf<String>().apply {
            if (classicEnabled) addAll(classicBlockedDomains)
            if (classicPauseEnabled) addAll(classicPauseBlockedDomains)
            addAll(exceededDomains)
        }

        val state = BlockPolicyState(
            currentMode = ActiveMode.NONE,
            focusEnabled = focusEnabled,
            blackoutEnabled = blackoutEnabled,
            classicEnabled = classicEnabled,
            classicPauseEnabled = classicPauseEnabled,
            focusBlockedPackages = focusBlockedPackages,
            classicBlockedPackages = classicBlockedPackages,
            classicBlockedDomains = classicBlockedDomains,
            classicPauseBlockedPackages = classicPauseBlockedPackages,
            classicPauseBlockedDomains = classicPauseBlockedDomains,
            exceededPackages = exceededPackages,
            exceededDomains = exceededDomains,
            blockedPackages = blockedPackages,
            blockedDomains = blockedDomains,
            blackoutAllowedPackages = getBlackoutEssentialPackages(context, homePackages),
            homePackages = homePackages,
            wakePackageName = context.packageName,
        )
        return state.copy(currentMode = ModeResolver.resolveCurrentMode(state))
    }

    fun refreshDailyLimitState(
        context: Context,
        snapshot: ForegroundSnapshot,
    ) {
        val preferences = prefs(context)
        val packageLimitConfig = readDailyLimitConfig(preferences, "package_limits")
        val websiteLimitConfig = readDailyLimitConfig(preferences, "website_limits")
        if (packageLimitConfig.isEmpty() && websiteLimitConfig.isEmpty()) {
            preferences.edit()
                .putString(exceededPackagesKey, JSONArray().toString())
                .putString(exceededWebsitesKey, JSONArray().toString())
                .apply()
            lastTrackedPackageName = snapshot.packageName
            lastTrackedDomain = snapshot.detectedBrowserUrl
            lastTrackedAtMillis = System.currentTimeMillis()
            return
        }

        val now = System.currentTimeMillis()
        val todayKey = currentDayKey(now)
        val persistedDayKey = preferences.getString(websiteUsageDayKeyPref, null)
        if (persistedDayKey != todayKey) {
            preferences.edit()
                .putString(websiteUsageDayKeyPref, todayKey)
                .putString(websiteUsageMillisKeyPref, JSONObject().toString())
                .putString(exceededWebsitesKey, JSONArray().toString())
                .apply()
        }

        val websiteUsage = readWebsiteUsage(preferences)
        val previousPackage = lastTrackedPackageName
        val previousDomain = lastTrackedDomain
        if (
            previousPackage != null &&
            previousDomain != null &&
            previousPackage == snapshot.packageName &&
            ForegroundAppDetector(context.packageName).isBrowserPackage(previousPackage) &&
            websiteLimitConfig.isNotEmpty()
        ) {
            val matched = matchingConfiguredDomain(previousDomain, websiteLimitConfig.keys)
            if (matched != null && lastTrackedAtMillis > 0L) {
                val elapsed = (now - lastTrackedAtMillis).coerceIn(0L, 60_000L)
                if (elapsed > 0L) {
                    websiteUsage[matched] = (websiteUsage[matched] ?: 0L) + elapsed
                }
            }
        }

        val exceededPackages = linkedSetOf<String>()
        packageLimitConfig.forEach { (pkg, limitMinutes) ->
            val usedMinutes = queryUsageMinutesToday(context, pkg)
            if (usedMinutes >= limitMinutes) {
                exceededPackages.add(pkg)
            }
        }

        val exceededDomains = linkedSetOf<String>()
        websiteLimitConfig.forEach { (domain, limitMinutes) ->
            val usedMinutes = ((websiteUsage[domain] ?: 0L) / 60_000L).toInt()
            if (usedMinutes >= limitMinutes) {
                exceededDomains.add(domain)
            }
        }

        persistWebsiteUsage(preferences, websiteUsage, todayKey)
        persistExceededDailyLimits(preferences, exceededPackages, exceededDomains)

        lastTrackedPackageName = snapshot.packageName
        lastTrackedDomain = snapshot.detectedBrowserUrl
        lastTrackedAtMillis = now
    }

    fun homePackages(context: Context): Set<String> {
        return try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
            }
            context.packageManager.queryIntentActivities(intent, 0)
                .mapNotNull { it.activityInfo?.packageName?.trim() }
                .filter { it.isNotEmpty() }
                .toSet()
        } catch (_: Exception) {
            emptySet()
        }
    }

    private fun getBlackoutEssentialPackages(
        context: Context,
        homePackages: Set<String>,
    ): Set<String> {
        val stored = parseNormalizedJSONArray(prefs(context).getString(blackoutAllowedPackagesKey, null))
        val allowed = linkedSetOf<String>()
        allowed.add(context.packageName)
        allowed.addAll(homePackages)
        defaultDialerPackage(context)?.let(allowed::add)
        defaultSmsPackage(context)?.let(allowed::add)
        allowed.addAll(findCalendarPackages(context))
        allowed.addAll(stored)
        return allowed
    }

    private fun findCalendarPackages(context: Context): Set<String> {
        val launchIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        return context.packageManager.queryIntentActivities(launchIntent, 0)
            .mapNotNull { resolveInfo ->
                val activityInfo = resolveInfo.activityInfo ?: return@mapNotNull null
                val pkg = activityInfo.packageName?.trim().orEmpty()
                if (pkg.isEmpty()) return@mapNotNull null
                val label = resolveInfo.loadLabel(context.packageManager)?.toString()?.trim().orEmpty()
                if (isLikelyCalendarApp(label, pkg)) pkg else null
            }
            .toSet()
    }

    private fun isLikelyCalendarApp(label: String, packageName: String): Boolean {
        val normalizedLabel = label.lowercase(Locale.getDefault())
        val normalizedPackage = packageName.lowercase(Locale.getDefault())
        return normalizedLabel.contains("calendar") ||
            normalizedLabel.contains("agenda") ||
            normalizedLabel.contains("calendrier") ||
            normalizedPackage.contains("calendar") ||
            normalizedPackage.contains("calendrier") ||
            normalizedPackage.contains("agenda")
    }

    private fun defaultDialerPackage(context: Context): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                context.getSystemService(TelecomManager::class.java)?.defaultDialerPackage
            } else {
                null
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun defaultSmsPackage(context: Context): String? {
        return try {
            Telephony.Sms.getDefaultSmsPackage(context)
        } catch (_: Exception) {
            null
        }
    }

    private fun prefs(context: Context) = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)

    private fun parsePackageArray(rawJson: String?, key: String): Set<String> {
        if (rawJson.isNullOrBlank()) return emptySet()
        return try {
            val json = JSONObject(rawJson)
            val array = json.optJSONArray(key) ?: return emptySet()
            buildSet {
                for (index in 0 until array.length()) {
                    val value = array.optString(index).trim()
                    if (value.isNotEmpty()) add(value)
                }
            }
        } catch (_: Exception) {
            emptySet()
        }
    }

    private fun parseDomainArray(rawJson: String?, key: String): Set<String> {
        if (rawJson.isNullOrBlank()) return emptySet()
        return try {
            val json = JSONObject(rawJson)
            val array = json.optJSONArray(key) ?: return emptySet()
            buildSet {
                for (index in 0 until array.length()) {
                    BrowserBlockCoordinator.normalizeDomainToken(array.optString(index))?.let(::add)
                }
            }
        } catch (_: Exception) {
            emptySet()
        }
    }

    private fun parseStringArray(rawJson: String?): Set<String> {
        if (rawJson.isNullOrBlank()) return emptySet()
        return try {
            val array = JSONArray(rawJson)
            buildSet {
                for (index in 0 until array.length()) {
                    val value = array.optString(index).trim()
                    if (value.isNotEmpty()) add(value)
                }
            }
        } catch (_: Exception) {
            emptySet()
        }
    }

    private fun parseNormalizedJSONArray(rawJson: String?): Set<String> {
        if (rawJson.isNullOrBlank()) return emptySet()
        return try {
            val array = JSONArray(rawJson)
            buildSet {
                for (index in 0 until array.length()) {
                    BrowserBlockCoordinator.normalizeDomainToken(array.optString(index))?.let(::add)
                }
            }
        } catch (_: Exception) {
            emptySet()
        }
    }

    private fun readDailyLimitConfig(
        preferences: android.content.SharedPreferences,
        key: String,
    ): Map<String, Int> {
        val rawJson = preferences.getString(dailyLimitConfigKey, null).orEmpty()
        if (rawJson.isEmpty()) return emptyMap()
        return try {
            val json = JSONObject(rawJson)
            val objectValue = json.optJSONObject(key) ?: return emptyMap()
            buildMap {
                val keys = objectValue.keys()
                while (keys.hasNext()) {
                    val rawKey = keys.next()
                    val normalizedKey = if (key == "website_limits") {
                        BrowserBlockCoordinator.normalizeDomainToken(rawKey)
                    } else {
                        rawKey.trim().ifEmpty { null }
                    } ?: continue
                    val minutes = objectValue.optInt(rawKey, 0)
                    if (minutes > 0) {
                        put(normalizedKey, minutes)
                    }
                }
            }
        } catch (_: Exception) {
            emptyMap()
        }
    }

    private fun readWebsiteUsage(
        preferences: android.content.SharedPreferences,
    ): MutableMap<String, Long> {
        val raw = preferences.getString(websiteUsageMillisKeyPref, null).orEmpty()
        if (raw.isEmpty()) return mutableMapOf()
        return try {
            val objectValue = JSONObject(raw)
            buildMap<String, Long> {
                val keys = objectValue.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    val normalized = BrowserBlockCoordinator.normalizeDomainToken(key) ?: continue
                    val millis = objectValue.optLong(key, 0L)
                    if (millis > 0L) {
                        put(normalized, millis)
                    }
                }
            }.toMutableMap()
        } catch (_: Exception) {
            mutableMapOf()
        }
    }

    private fun persistWebsiteUsage(
        preferences: android.content.SharedPreferences,
        usage: Map<String, Long>,
        dayKey: String,
    ) {
        val payload = JSONObject()
        usage.forEach { (domain, millis) -> payload.put(domain, millis) }
        preferences.edit()
            .putString(websiteUsageDayKeyPref, dayKey)
            .putString(websiteUsageMillisKeyPref, payload.toString())
            .apply()
    }

    private fun persistExceededDailyLimits(
        preferences: android.content.SharedPreferences,
        exceededPackages: Set<String>,
        exceededDomains: Set<String>,
    ) {
        val packageArray = JSONArray()
        exceededPackages.forEach(packageArray::put)
        val domainArray = JSONArray()
        exceededDomains.forEach(domainArray::put)
        preferences.edit()
            .putString(exceededPackagesKey, packageArray.toString())
            .putString(exceededWebsitesKey, domainArray.toString())
            .putBoolean(
                "classic_daily_limit_active",
                exceededPackages.isNotEmpty() || exceededDomains.isNotEmpty(),
            )
            .apply()
    }

    private fun queryUsageMinutesToday(context: Context, packageName: String): Int {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            calendar.timeInMillis,
            System.currentTimeMillis(),
        )
        if (stats.isNullOrEmpty()) return 0
        val millis = stats
            .filter { it.packageName == packageName }
            .sumOf { it.totalTimeInForeground }
        return (millis / 60_000L).toInt()
    }

    private fun currentDayKey(nowMillis: Long): String {
        val calendar = Calendar.getInstance().apply {
            timeInMillis = nowMillis
        }
        return String.format(
            Locale.US,
            "%04d-%03d",
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.DAY_OF_YEAR),
        )
    }

    private fun matchingConfiguredDomain(
        currentDomain: String,
        candidates: Set<String>,
    ): String? {
        return candidates
            .filter {
                currentDomain == it || currentDomain.endsWith(".$it")
            }
            .maxByOrNull { it.length }
    }
}
