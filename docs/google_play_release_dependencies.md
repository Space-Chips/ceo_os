# Google Play Release Dependencies — WakeApp

Date: 2026-03-28  
Project: WakeApp  
Scope: Android release dependencies outside the core blocking implementation

## Purpose
This document isolates the Android release dependencies that can break Google Play publication even when the app code itself is correct.

It is intentionally separate from the blocking-stack checklist because these items live across:
- Play Console
- Google Cloud / OAuth configuration
- RevenueCat
- release signing
- public policy/account-deletion pages

---

## 1. Current Repo Status

Validated in the repo today:
- Android package is now aligned to `com.wakeapp.ceoos`
- Release signing scaffolding exists in:
  - [/Users/timo/ceo_os/android/app/build.gradle.kts](/Users/timo/ceo_os/android/app/build.gradle.kts)
  - [/Users/timo/ceo_os/android/key.properties.example](/Users/timo/ceo_os/android/key.properties.example)
- Google Sign-In mobile config is now platform-aware:
  - Android no longer depends on an iOS client ID
  - Files:
    - [/Users/timo/ceo_os/lib/core/config/supabase_config.dart](/Users/timo/ceo_os/lib/core/config/supabase_config.dart)
    - [/Users/timo/ceo_os/lib/core/providers/auth_provider.dart](/Users/timo/ceo_os/lib/core/providers/auth_provider.dart)
- Billing UI and legal wording are now platform-aware for Apple / Google Play:
  - [/Users/timo/ceo_os/lib/components/premium_gate_dialog.dart](/Users/timo/ceo_os/lib/components/premium_gate_dialog.dart)
  - [/Users/timo/ceo_os/lib/features/profile/profile_screen.dart](/Users/timo/ceo_os/lib/features/profile/profile_screen.dart)

Not present in the repo today:
- no `android/key.properties`
- no Android upload keystore committed
- no `google-services.json`

That absence is normal for secrets, but it means Android release is not fully wired yet.

---

## 2. Google Sign-In Android Release

### What the code expects
- `GOOGLE_WEB_CLIENT_ID` must be available
- Android mobile sign-in is considered available when the web client ID is present
- iOS client ID is no longer required for Android

### What must exist outside the repo
- an Android OAuth client for package `com.wakeapp.ceoos`
- SHA-1 / SHA-256 fingerprints registered for the Android signing certificate(s)
- Google provider configured correctly in Supabase

### Important Play App Signing nuance
If you use Play App Signing, Android sign-in may need both:
- your upload certificate fingerprint
- Google Play App Signing certificate fingerprint

If only the upload key is configured and Play re-signs the app, Google Sign-In can work in internal builds but fail in production.

### Manual checklist
- [ ] Create or verify the Android OAuth client for `com.wakeapp.ceoos`
- [ ] Add upload-key SHA-1 / SHA-256
- [ ] Add Play App Signing SHA-1 / SHA-256 after Play is configured
- [ ] Confirm Supabase Google auth is configured with the right web client ID
- [ ] Confirm Google Sign-In works in a signed Android release build, not only debug

---

## 3. RevenueCat + Google Play Billing

### What the code expects
- `revenuecat_android_api_key` must exist in the premium app config row
- offerings/products must exist in RevenueCat
- Google Play products must be mapped correctly to RevenueCat
- backend sync remains dependent on:
  - [/Users/timo/ceo_os/supabase/functions/revenuecat-webhook/index.ts](/Users/timo/ceo_os/supabase/functions/revenuecat-webhook/index.ts)

### Manual checklist
- [ ] Create the Android app in RevenueCat if not already done
- [ ] Add the Google Play app / package mapping
- [ ] Create subscriptions in Play Console
- [ ] Create base plans and offers if needed
- [ ] Map Play products to RevenueCat entitlements/offering
- [ ] Set `revenuecat_android_api_key` in the app config row
- [ ] Verify `revenuecat_entitlement_id` and `revenuecat_offering_id`
- [ ] Verify purchase flow in internal testing
- [ ] Verify restore purchases in internal testing
- [ ] Verify webhook sync updates `billing_subscriptions`

### Failure modes to avoid
- Android paywall shows offers but purchase fails because products are not active
- purchase succeeds in Play but entitlement does not unlock because RevenueCat mapping is incomplete
- restore works in store but backend sync lags indefinitely because the webhook is not live

---

## 4. Release Signing

### Required before Play upload
- [ ] Generate an Android upload keystore
- [ ] Create `android/key.properties` from
  [/Users/timo/ceo_os/android/key.properties.example](/Users/timo/ceo_os/android/key.properties.example)
- [ ] Verify the release build resolves the release signing config
- [ ] Enable Play App Signing in Play Console

### Recommendation
Use:
- Google-managed app signing key in Play
- separate upload key in your local setup

---

## 5. Account Deletion Outside the App

Google Play requires account deletion support for apps that let users create accounts.

You already have in-app deletion, but Play also expects a public web resource when applicable.

### Manual checklist
- [ ] Publish a public account deletion support page
- [ ] Publish or verify a public privacy policy page
- [ ] Add the account deletion URL in Play Console
- [ ] Ensure the web page matches the in-app deletion behavior

Minimum content the deletion page should explain:
- users can delete their account from inside the app
- what data is deleted
- whether any data may be retained for legal/security reasons
- how subscriptions must be canceled separately in the relevant store if applicable

---

## 6. Play Console Tracks and Testing

### Internal release
- [ ] Upload the first signed Android App Bundle
- [ ] Run internal testing before any broader rollout
- [ ] Verify Google Sign-In
- [ ] Verify Premium purchase
- [ ] Verify restore
- [ ] Verify Accessibility / Usage Access / overlay flows on a real Android phone

### If your Play developer account is subject to new-account testing rules
- [ ] Complete the required closed testing period before requesting production

---

## 7. Go / No-Go for Android Release Dependencies

### No-Go if any of these are false
- [ ] Package name in Play Console matches `com.wakeapp.ceoos`
- [ ] Upload keystore exists and release signing is configured
- [ ] Google Sign-In Android release certs are configured
- [ ] RevenueCat Android API key is live
- [ ] Google Play subscription products exist and are mapped
- [ ] Public privacy policy URL exists
- [ ] Public account deletion URL exists

### Go when all are true
At that point, the remaining work becomes:
- Play listing
- App Content / Data Safety
- testing tracks
- final reviewer notes / declarations
