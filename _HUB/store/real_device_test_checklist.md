# WakeApp — Real-Device Test Checklist (blocking stack + commerce)

Run on a **physical iPhone** signed into a sandbox Apple ID. Family Controls,
Screen Time blocking, and StoreKit purchases cannot be validated on Simulator.

> Source `docs/real_device_test_plan_blocking_stack.md` is empty in the repo — this
> checklist is reconstructed from the A5 brief scope. Update the source doc if a
> canonical plan is authored later.

## 0. Pre-conditions
- [ ] Build installed from a `--release` IPA with Supabase dart-defines set.
- [ ] Device iOS version ≥ deployment target; signed into a **sandbox** account.
- [ ] Screen Time enabled on the device (Settings ▸ Screen Time).

## 1. Family Controls authorization
- [ ] First launch of blocking flow prompts for Screen Time / Family Controls access.
- [ ] Granting access succeeds; denying shows a graceful, honest fallback (no crash).
- [ ] App/category/website picker (FamilyActivityPicker) opens and selections persist
      across app restart.

## 2. Focus blocking
- [ ] Start a Focus session selecting apps/categories to block.
- [ ] Blocked apps are shielded while the session is active (shield screen appears).
- [ ] Ending / expiry of the session lifts the shield.
- [ ] Session survives app backgrounding and device lock/unlock.

## 3. CEO Mode / Blackout
- [ ] Activate CEO Mode; confirm the stricter block set applies.
- [ ] Blackout / preparation flow completes and enforces the block as configured.
- [ ] Attempting to bypass (open a blocked app) is correctly prevented.
- [ ] Deactivation path works and restores normal access.

## 4. Screen Time setup
- [ ] Screen Time setup screen completes end-to-end.
- [ ] Selected limits/blocks reflect in the live blocking behaviour.

## 5. Purchase (sandbox StoreKit)
- [ ] Paywall (`premium_paywall.dart`) renders price, terms, and required legal links.
- [ ] Purchase a subscription with the sandbox account → entitlement unlocks premium.
- [ ] Cancel mid-purchase → app handles gracefully, no false unlock.
- [ ] Premium-gated features become available only after successful purchase.

## 6. Restore purchases
- [ ] "Restore purchases" on a fresh install / reinstall re-grants the entitlement.
- [ ] Restore with no prior purchase shows an honest "nothing to restore" message.

## 7. Account deletion
- [ ] In-app account deletion completes and signs the user out.
- [ ] Server-side data is removed (verify in Supabase) per the privacy policy.
- [ ] Re-registering with the same email starts fresh (no stale data).

## 8. Age gate (recent change)
- [ ] Signup enforces the minimum-age gate; under-age input is blocked with a clear message.
- [ ] Valid age proceeds to account creation.

## 9. Offline behaviour
- [ ] Launch / use core flows with airplane mode on → no crash; offline state messaged.
- [ ] Active block continues to enforce while offline.
- [ ] Returning online re-syncs state with Supabase without data loss.

## 10. Auth error copy (recent change)
- [ ] Wrong password, unconfirmed email, and generic failures show the friendly,
      reviewer-readable messages from `auth_support.dart`.

## Sign-off
- [ ] Tester: ____________  Device/iOS: ____________  Build: 1.0.0+19  Date: __________
- [ ] All blocking, purchase, restore, deletion, and offline paths verified.
