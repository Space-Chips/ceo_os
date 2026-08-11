package com.wakeapp.ceoos.domain.block

import com.wakeapp.ceoos.ActiveMode
import com.wakeapp.ceoos.BlockPolicyState
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class GetBlockDecisionUseCaseTest {
    @Test
    fun `blackout has priority over focus and classic limit`() {
        val targetPackage = "com.example.target"
        val useCase = GetBlockDecisionUseCase {
            baseState(
                blackoutEnabled = true,
                focusEnabled = true,
                focusBlockedPackages = setOf(targetPackage),
                exceededPackages = setOf(targetPackage),
            )
        }

        val decision = useCase.isBlocked(targetPackage)

        assertTrue(decision.blocked)
        assertEquals(BlockReason.BLACKOUT_SESSION, decision.reason)
    }

    @Test
    fun `focus has priority over classic limit when blackout is inactive`() {
        val targetPackage = "com.example.target"
        val useCase = GetBlockDecisionUseCase {
            baseState(
                focusEnabled = true,
                focusBlockedPackages = setOf(targetPackage),
                exceededPackages = setOf(targetPackage),
            )
        }

        val decision = useCase.isBlocked(targetPackage)

        assertTrue(decision.blocked)
        assertEquals(BlockReason.FOCUS_SESSION, decision.reason)
    }

    @Test
    fun `classic limit reached blocks when no higher priority mode applies`() {
        val targetPackage = "com.example.target"
        val useCase = GetBlockDecisionUseCase {
            baseState(
                exceededPackages = setOf(targetPackage),
            )
        }

        val decision = useCase.isBlocked(targetPackage)

        assertTrue(decision.blocked)
        assertEquals(BlockReason.CLASSIC_LIMIT_REACHED, decision.reason)
    }

    @Test
    fun `system exempt packages are never blocked`() {
        val useCase = GetBlockDecisionUseCase {
            baseState(
                blackoutEnabled = true,
                focusEnabled = true,
                focusBlockedPackages = setOf("com.android.systemui"),
                exceededPackages = setOf("com.android.systemui"),
            )
        }

        val decision = useCase.isBlocked("com.android.systemui")

        assertFalse(decision.blocked)
        assertNull(decision.reason)
    }

    private fun baseState(
        focusEnabled: Boolean = false,
        blackoutEnabled: Boolean = false,
        focusBlockedPackages: Set<String> = emptySet(),
        exceededPackages: Set<String> = emptySet(),
    ): BlockPolicyState {
        return BlockPolicyState(
            currentMode = ActiveMode.NONE,
            focusEnabled = focusEnabled,
            blackoutEnabled = blackoutEnabled,
            classicEnabled = false,
            classicPauseEnabled = false,
            focusBlockedPackages = focusBlockedPackages,
            classicBlockedPackages = emptySet(),
            classicBlockedDomains = emptySet(),
            classicPauseBlockedPackages = emptySet(),
            classicPauseBlockedDomains = emptySet(),
            exceededPackages = exceededPackages,
            exceededDomains = emptySet(),
            blockedPackages = emptySet(),
            blockedDomains = emptySet(),
            blackoutAllowedPackages = setOf(
                "com.wakeapp.ceoos",
                "com.android.launcher",
            ),
            homePackages = setOf("com.android.launcher"),
            wakePackageName = "com.wakeapp.ceoos",
        )
    }
}
