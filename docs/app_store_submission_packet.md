# App Store Submission Packet — WakeApp

Date: 2026-03-23  
Project: WakeApp  
Audience: App Store Review / internal release prep

## Goal
This document is the final Apple-facing submission packet for WakeApp.
It is designed to maximize clarity around Family Controls usage and reduce avoidable review friction.

It should be used together with:
- [/Users/timo/ceo_os/docs/real_device_test_plan_blocking_stack.md](/Users/timo/ceo_os/docs/real_device_test_plan_blocking_stack.md)
- [/Users/timo/ceo_os/docs/store_submission_checklist_blocking_stack.md](/Users/timo/ceo_os/docs/store_submission_checklist_blocking_stack.md)

---

## 1. Ready-to-paste App Review Notes

Paste the text below into the **App Review Notes** field in App Store Connect.

CEO OS is a personal focus and self-control app. On iPhone, it uses Apple's official Screen Time APIs through Family Controls, Managed Settings, and Device Activity to let the user select apps and websites, start protected focus sessions, schedule restriction windows, and apply time-based limits.

The app does not use private APIs, remote device management, or hidden enforcement. Restrictions are user-initiated and rely on Apple's intended Screen Time framework behavior.

Primary review flows:
1. Focus Mode: start a timed focus session and verify selected distracting apps and websites are restricted during the session.
2. Blackout Mode: start a stricter focus session and verify the same Screen Time-based restriction flow.
3. Classic Blocking: select apps and websites to restrict outside timed sessions.
4. Planned Pauses and Daily Limits: create a scheduled restriction window or a short daily limit, then verify the restriction activates when triggered.

How to test on iPhone:
1. Open WakeApp and go to the Screen Time / blocking area.
2. Grant the requested Screen Time / Family Controls permission.
3. Select one or more apps or websites to restrict.
4. Start Focus Mode, Blackout Mode, or a classic blocking configuration.
5. Attempt to open the selected blocked targets while the restriction is active.

Important context:
- WakeApp is a self-control and digital wellbeing product, not a surveillance or device administration app.
- The app uses Apple's official APIs and does not claim stronger guarantees than the system actually provides.
- Account deletion is available directly in the app and permanently removes the account when the backend function is deployed in production.

If a review account is needed, provide the test credentials below this note. Keep the backend environment live for the full review window.

---

## 2. Family Controls Justification

Use this wording when explaining why the entitlement is needed.

WakeApp uses Family Controls because blocking and scheduling are core features of the product on iPhone. Users explicitly choose apps and websites they want to restrict, then start focus sessions, planned pauses, or time-based limits. Family Controls, Managed Settings, and Device Activity are used only to support these user-initiated Screen Time flows.

WakeApp does not request this capability to inspect unrelated activity, access protected data outside the intended framework, or obtain broader device control than necessary for the product. Screen Time usage data and blocking-attempt data are not shared beyond the individual user, including through server logging, screenshots, exports, or social comparisons.

---

## 3. Reviewer Walkthrough

Use this if review asks for a simpler test script.

### Fast path
1. Install the build on a real iPhone.
2. Sign in or use the provided test account.
3. Open the Screen Time / blocking section.
4. Grant Screen Time permission.
5. Select one app and one website.
6. Start a 5-minute Focus Mode session.
7. Try opening the selected targets.

Expected result:
- the selected targets are restricted while the session is active
- the restriction ends when the session ends unless another rule still applies

### Secondary checks
1. Start Blackout Mode and verify the same restriction path works.
2. Create a planned pause that starts within a few minutes.
3. Create a short daily limit and verify the selected target becomes restricted after the threshold.

---

## 4. Review Account Template

Fill this in before submission if review needs credentials.

- Test account email: `REPLACE_ME`
- Test account password: `REPLACE_ME`
- 2FA requirement: `No` unless explicitly enabled for review
- Premium access: `Yes` if any Family Controls flow is premium-gated
- Backend region / environment: `Production review environment`
- Notes: keep this account stable during the full review period

---

## 5. App Privacy Alignment Notes

These points should match App Store Connect answers and the in-app legal text.

- Account data: email, profile name, settings, and synced productivity records may be linked to the user account.
- Purchases: Apple and RevenueCat may process subscription and purchase state.
- Sign-in: Google Sign-In is used only if the user explicitly chooses it.
- Screen Time / blocking configuration: selected apps, websites, schedules, and related settings may be stored to sync the user's setup across their account.
- Usage-related product data: daily-limit and focus-related stats may be processed to provide history and insights.
- Data is not described as being used for advertising or sold to data brokers.

Before submission, confirm the App Privacy form matches the real production behavior exactly.

---

## 6. Submission Guardrails

Keep these statements true in the binary and in metadata.

### Safe claims
- Helps users block selected distracting apps and websites
- Uses Apple Screen Time APIs on iPhone
- Supports focus sessions, planned pauses, and daily limits
- Supports self-control and digital wellbeing use cases

### Claims to avoid
- Impossible to bypass
- Permanent device lockout
- Stronger control than Apple's Screen Time system actually provides
- Unbounded monitoring or administrative control over the device

---

## 7. Manual Checks Before Pressing Submit

- [ ] Real-device iPhone validation completed for permission flow, Focus Mode, Blackout Mode, classic blocking, planned pauses, and daily limits
- [ ] Apple Developer portal capability is enabled for all relevant App IDs / targets
- [ ] Provisioning profiles refreshed after entitlement changes
- [ ] Production backend needed for review is deployed and stable
- [ ] Account deletion edge function is deployed in production
- [ ] No Screen Time / Device Activity usage data or blocking-attempt data is sent to the backend, exported, or shared outside the individual user flow
- [ ] Review account is created and documented if needed
- [ ] App Privacy answers in App Store Connect match the real app behavior
- [ ] App Review Notes pasted into App Store Connect

---

## 8. Recommendation

For Family Controls approval, clarity matters as much as implementation.
This packet keeps the product story narrow, privacy-respectful, and consistent with Apple's intended Screen Time model:
- self-control
- user-initiated restrictions
- minimum necessary capability
- no exaggerated lockout claims
