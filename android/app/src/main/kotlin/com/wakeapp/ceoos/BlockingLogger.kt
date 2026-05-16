package com.wakeapp.ceoos

import android.util.Log

object BlockingLogger {
    private const val tag = "WakeBlocking"

    data class Entry(
        val eventType: Int,
        val packageName: String?,
        val className: String?,
        val detectedUrl: String?,
        val decision: String,
        val gateLaunched: Boolean,
        val gateFailureReason: String?,
        val latencyMillis: Long,
        val eventDelayMillis: Long,
        val timestampMillis: Long,
        val mode: String,
    )

    @Volatile
    private var lastEntry: Entry? = null

    fun record(
        eventType: Int,
        packageName: String?,
        className: String?,
        detectedUrl: String?,
        decision: String,
        gateLaunched: Boolean,
        gateFailureReason: String?,
        latencyMillis: Long,
        eventDelayMillis: Long,
        mode: String,
    ) {
        val entry = Entry(
            eventType = eventType,
            packageName = packageName,
            className = className,
            detectedUrl = detectedUrl,
            decision = decision,
            gateLaunched = gateLaunched,
            gateFailureReason = gateFailureReason,
            latencyMillis = latencyMillis,
            eventDelayMillis = eventDelayMillis,
            timestampMillis = System.currentTimeMillis(),
            mode = mode,
        )
        lastEntry = entry
        Log.d(
            tag,
                "[event=${entry.eventType}] [pkg=${entry.packageName}] [cls=${entry.className}] " +
                "[url=${entry.detectedUrl}] [decision=${entry.decision}] " +
                "[gate_launched=${entry.gateLaunched}] [gate_failure=${entry.gateFailureReason}] " +
                "[latency_ms=${entry.latencyMillis}] [event_delay_ms=${entry.eventDelayMillis}] " +
                "[mode=${entry.mode}]",
        )
    }

    fun snapshot(): Map<String, Any?> {
        val entry = lastEntry
        return mapOf(
            "eventType" to entry?.eventType,
            "packageName" to entry?.packageName,
            "className" to entry?.className,
            "detectedUrl" to entry?.detectedUrl,
            "decision" to entry?.decision,
            "gateLaunched" to entry?.gateLaunched,
            "gateFailureReason" to entry?.gateFailureReason,
            "latencyMillis" to entry?.latencyMillis,
            "eventDelayMillis" to entry?.eventDelayMillis,
            "timestampMillis" to entry?.timestampMillis,
            "mode" to entry?.mode,
        )
    }
}
