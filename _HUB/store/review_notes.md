# App Review Notes — The WakeApp (App Store Connect)

> Paste into App Store Connect → App Review Information → Notes.
> Built from `docs/app_store_submission_packet.md`, updated for brand **The WakeApp**, with demo account, on-device Screen Time explanation, and blocking test instructions.
> Bundle: `com.wakeapp.ceoos` · SKU `wakeapp-ios` · Apple ID `6760942950` · iPhone only (no iPad, no Apple Watch).

---

## 1. Ready-to-paste App Review Notes

> The WakeApp is a personal focus and self-control app — a customizable control center for staying off distracting apps. On iPhone, it uses Apple's official Screen Time APIs (Family Controls, Managed Settings, Device Activity) so the user can select apps and websites, start protected focus sessions, schedule restriction windows, and apply time-based daily limits. The app uses no private APIs, no remote device management, and no hidden enforcement — all restrictions are user-initiated and rely on Apple's intended Screen Time behavior.
>
> The app contains NO AI features.
>
> IMPORTANT — Screen Time data stays on device: the apps and websites a user selects are returned by Apple's Family Controls API as opaque tokens (not human-readable names). These tokens never leave the device. We do not log, export, screenshot, or share Screen Time selections or blocking-attempt data to our backend or any third party.
>
> Premium note: the Family Controls blocking flows are Premium-gated. The demo account below already has Premium enabled, so no purchase is required to review the blocking features.
>
> Primary review flows:
> 1. Focus Mode — start a timed focus session; selected distracting apps/websites are restricted during the session.
> 2. Blackout Mode — start a stricter focus session; same Screen Time-based restriction flow.
> 3. Classic Blocking — select apps/websites to restrict outside of timed sessions.
> 4. Planned Pauses & Daily Limits — create a scheduled restriction window or a short daily limit and verify it activates when triggered.
>
> Please review on a real iPhone (Family Controls restrictions do not function in the Simulator).

---

## 2. Demo / Review account (FILL BEFORE SUBMISSION)

- **Test account email:** `REPLACE_ME`
- **Test account password:** `REPLACE_ME`
- **2FA required:** No (do not enable 2FA on the review account)
- **Premium access:** Yes — pre-enabled (entitlement `premium`) so all Family Controls flows are reviewable without purchase
- **Backend environment:** Production review environment — keep it live and stable for the entire review window
- **Notes:** Do not delete or modify this account during review.

⚠️ FOUNDER: create this account, enable Premium server-side, and paste the credentials above before submitting.

---

## 3. How to test the blocking (step-by-step for the reviewer)

**Setup**
1. Install the build on a **real iPhone** (not the Simulator).
2. Sign in with the demo account above.
3. Open the Screen Time / blocking section of the app.
4. When prompted, grant the **Screen Time / Family Controls** permission (the iOS system sheet).
5. Select one or more apps and/or one website to restrict.

**Fast path (Focus Mode)**
6. Start a **5-minute Focus Mode** session.
7. Leave WakeApp and try to open one of the selected blocked apps/websites.
8. Expected: the selected targets are restricted while the session is active; the restriction ends when the session ends (unless another rule still applies).

**Secondary checks**
9. Start **Blackout Mode** and verify the same restriction path works.
10. Create a **Planned Pause** scheduled to start within a couple of minutes and verify it activates.
11. Create a short **Daily Limit** on a selected target and verify it becomes restricted after the threshold.

---

## 4. Family Controls justification (paste if review asks)

> The WakeApp uses Family Controls because blocking and scheduling are core features of the product on iPhone. Users explicitly choose the apps and websites they want to restrict, then start focus sessions, planned pauses, or time-based limits. Family Controls, Managed Settings, and Device Activity are used only to support these user-initiated Screen Time flows. The app does not request this capability to inspect unrelated activity, access protected data outside the intended framework, or obtain broader device control than necessary. Screen Time selections and blocking-attempt data are never shared beyond the individual user (no server logging, screenshots, exports, or social comparisons).

---

## 5. Subscription / paywall review (paste if review asks)

> Premium (`com.wakeapp.pro.monthly`, `com.wakeapp.pro.yearly`) is an auto-renewable subscription managed via RevenueCat with the App Store as the billing processor. Every paywall entry point shows the product name (WakeApp Premium), the monthly and yearly options with store-localized prices, the auto-renew disclosure, and always-accessible Restore Purchases, Manage Subscription, Terms of Use, and Privacy Policy links. The demo account already has Premium, so no purchase is needed to review gated features.

---

## 6. Guardrails kept true in binary + metadata

Safe claims used: blocks selected distracting apps/websites · uses Apple Screen Time APIs on iPhone · supports focus sessions, planned pauses, daily limits · self-control & digital wellbeing.
Claims avoided: "impossible to bypass", "permanent lockout", control stronger than Apple's Screen Time, unbounded monitoring/administration, any "AI".

---

## 7. Pre-submit manual checks

- [ ] Real-device iPhone validation: permission flow, Focus Mode, Blackout Mode, classic blocking, planned pauses, daily limits
- [ ] Family Controls capability enabled for all relevant App IDs / targets
- [ ] Provisioning profiles refreshed after entitlement changes
- [ ] Production backend for review deployed and stable
- [ ] Account-deletion edge function deployed in production
- [ ] No Screen Time / Device Activity / blocking-attempt data sent to backend, exported, or shared
- [ ] Demo account created, Premium enabled, credentials pasted in §2
- [ ] App Privacy answers match real behavior (see `app_privacy_labels.md`)
- [ ] These review notes pasted into App Store Connect
- [ ] Sign in with Apple offered if Google Sign-In ships (guideline 4.8) — or confirm email/password meets 4.8
