package com.wakeapp.ceoos

import java.util.Locale

class BrowserBlockCoordinator {
    companion object {
        fun normalizeDomainToken(raw: String?): String? {
            val value = raw?.trim()?.lowercase(Locale.US).orEmpty()
            if (value.isEmpty() || value == "__adult_content__") return null

            var normalized = value
                .replaceFirst(Regex("^https?://"), "")
                .replaceFirst(Regex("^www\\d*\\."), "")
                .replaceFirst(Regex("^m\\."), "")

            if (normalized.contains("@")) {
                normalized = normalized.substringAfterLast('@')
            }

            normalized = normalized.substringBefore('/')
                .substringBefore('?')
                .substringBefore('#')
                .substringBefore(':')
                .trim('.')

            if (normalized.isEmpty()) return null
            if (normalized.contains(' ')) return null
            if (!normalized.contains('.')) return null
            return normalized
        }
    }

    fun matchDomain(domain: String, configuredDomains: Set<String>): String? {
        val normalizedDomain = normalizeDomainToken(domain) ?: return null
        return configuredDomains.firstOrNull { configured ->
            val normalizedConfigured = normalizeDomainToken(configured) ?: return@firstOrNull false
            normalizedDomain == normalizedConfigured ||
                normalizedDomain.endsWith(".$normalizedConfigured")
        }
    }
}
