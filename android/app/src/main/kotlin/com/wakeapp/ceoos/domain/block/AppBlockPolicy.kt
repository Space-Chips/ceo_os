package com.wakeapp.ceoos.domain.block

interface AppBlockPolicy {
    fun isBlocked(packageName: String): BlockDecision
}
