# Android Release Runbook — WakeApp

Date: 2026-03-28  
Project: WakeApp  
Scope: Exact manual steps to get from repo-ready Android code to a valid Google Play internal test release

## 1. Goal

This runbook is the execution layer for Android release.

Use it when you are ready to move from:
- code and policy preparation

to:
- a signed Android App Bundle
- a configured Play Console app
- working Google Sign-In release
- working Google Play Billing / RevenueCat release

---

## 2. Current Assumptions

These values are already aligned in the repo:
- package name: `com.wakeapp.ceoos`
- app name: `WakeApp`

Relevant files:
- [/Users/timo/ceo_os/android/app/build.gradle.kts](/Users/timo/ceo_os/android/app/build.gradle.kts)
- [/Users/timo/ceo_os/android/key.properties.example](/Users/timo/ceo_os/android/key.properties.example)
- [/Users/timo/ceo_os/docs/google_play_submission_packet.md](/Users/timo/ceo_os/docs/google_play_submission_packet.md)

Do not change the package name unless you are absolutely certain, because Google says package names are unique and permanent once used in Play Console.

---

## 3. Step A — Create the Play Console app

In Play Console:
1. Create app
2. Default language: choose your main release language
3. App name: `WakeApp`
4. App or game: `App`
5. Free or paid: choose your real business model now
6. Add the support email you will actively monitor
7. Accept the declarations and Play App Signing terms

Do this before deeper external config, so the package identity and Play app exist.

---

## 4. Step B — Create the Android upload keystore

Run a command like this on your machine:

```bash
keytool -genkeypair \
  -v \
  -keystore ~/ceo-os-upload-key.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000
```

Recommended:
- keep the keystore outside the repo
- use a password manager for the store password and key password
- keep a secure backup

Then create:
- [`/Users/timo/ceo_os/android/key.properties`](/Users/timo/ceo_os/android/key.properties.example)

With content based on:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/absolute/path/to/your/upload-keystore.jks
```

Important:
- never commit `android/key.properties`
- never commit the keystore

---

## 5. Step C — Enable Play App Signing

In Play Console:
1. Go to App integrity
2. Enable Play App Signing
3. Prefer a Google-managed app signing key
4. Keep your own upload key locally

Why this matters:
- Google will re-sign production builds
- Google Sign-In release can fail if you only register your upload certificate and forget the Play signing certificate

After Play App Signing is enabled, collect:
- upload certificate SHA-1
- upload certificate SHA-256
- Play App Signing certificate SHA-1
- Play App Signing certificate SHA-256

---

## 6. Step D — Configure Google Sign-In Android release

Outside the repo, you need:
- an Android OAuth client for `com.wakeapp.ceoos`
- the release certificate fingerprints registered with the provider
- Supabase Google auth configured correctly

Practical sequence:
1. Create or verify the Android OAuth client for package `com.wakeapp.ceoos`
2. Add the upload key SHA-1 / SHA-256
3. Add the Play App Signing SHA-1 / SHA-256
4. Verify your `GOOGLE_WEB_CLIENT_ID` is the one expected by Supabase
5. Keep Android sign-in platform-aware in app config

Relevant code:
- [/Users/timo/ceo_os/lib/core/config/supabase_config.dart](/Users/timo/ceo_os/lib/core/config/supabase_config.dart)
- [/Users/timo/ceo_os/lib/core/providers/auth_provider.dart](/Users/timo/ceo_os/lib/core/providers/auth_provider.dart)

Success condition:
- Google Sign-In works in a signed Android release build, not only debug

---

## 7. Step E — Configure Google Play Billing + RevenueCat

In Play Console:
1. Create the subscription products you actually want to sell
2. Create base plans
3. Create offers if relevant

In RevenueCat:
1. Create the Android app if not already present
2. Connect the Play package `com.wakeapp.ceoos`
3. Map Play subscriptions to RevenueCat products
4. Map those products to the entitlement and offering used by the app

In your backend/app config:
1. Ensure `revenuecat_android_api_key` is set in the premium app config row
2. Ensure the RevenueCat webhook is live

Relevant files:
- [/Users/timo/ceo_os/lib/core/services/billing_service.dart](/Users/timo/ceo_os/lib/core/services/billing_service.dart)
- [/Users/timo/ceo_os/lib/core/repositories/premium_repository.dart](/Users/timo/ceo_os/lib/core/repositories/premium_repository.dart)
- [/Users/timo/ceo_os/supabase/functions/revenuecat-webhook/index.ts](/Users/timo/ceo_os/supabase/functions/revenuecat-webhook/index.ts)

Success conditions:
- purchase succeeds in internal testing
- entitlement unlocks correctly
- restore works correctly
- webhook updates backend subscription state

---

## 8. Step F — Publish the required public web pages

Before broader Play release, you need:
- a public privacy policy URL
- a public account deletion support URL

Those pages should be:
- live
- public
- non-geofenced
- not PDFs
- consistent with the app and Data Safety answers

Prepared copy:
- [/Users/timo/ceo_os/docs/site_privacy_policy.md](/Users/timo/ceo_os/docs/site_privacy_policy.md)
- [/Users/timo/ceo_os/docs/site_account_deletion.md](/Users/timo/ceo_os/docs/site_account_deletion.md)

---

## 9. Step G — Fill Play Console App Content

Recommended order:
1. Privacy Policy
2. Ads declaration
3. App access, if reviewer credentials are needed
4. Content rating
5. Target audience and content
6. Data Safety
7. Data deletion / account deletion
8. Permission declarations if Play surfaces them

Prepared guidance:
- [/Users/timo/ceo_os/docs/google_play_data_safety_worksheet.md](/Users/timo/ceo_os/docs/google_play_data_safety_worksheet.md)
- [/Users/timo/ceo_os/docs/store_review_notes_and_disclosures.md](/Users/timo/ceo_os/docs/store_review_notes_and_disclosures.md)

---

## 10. Step H — Build and upload the first internal test bundle

Once signing is configured and the Android SDK is available locally:

```bash
flutter build appbundle --release
```

Expected artifact:
- `build/app/outputs/bundle/release/app-release.aab`

Upload that bundle to:
- Internal testing first

Do not jump to production first.

---

## 11. Step I — Real-device release validation

On a physical Android phone, validate:
- login
- Google Sign-In if exposed
- Focus Mode
- Blackout Mode
- app blocking
- website blocking in supported browsers
- daily limits
- reboot / time-change behavior
- purchase
- restore
- account deletion

Supporting docs:
- [/Users/timo/ceo_os/docs/real_device_test_plan_blocking_stack.md](/Users/timo/ceo_os/docs/real_device_test_plan_blocking_stack.md)
- [/Users/timo/ceo_os/docs/google_play_submission_packet.md](/Users/timo/ceo_os/docs/google_play_submission_packet.md)

---

## 12. Step J — Move toward production

Only move past internal testing when all are true:
- signed release bundle works
- Google Sign-In release works
- RevenueCat + Play Billing work
- privacy policy URL is live
- account deletion URL is live
- Data Safety answers are accurate
- required declarations are complete
- real-device validation has passed
- closed testing requirement is satisfied if your developer account is in scope

---

## 13. Fast Checklist

- [ ] Play app created with `com.wakeapp.ceoos`
- [ ] upload keystore created
- [ ] `android/key.properties` created locally
- [ ] Play App Signing enabled
- [ ] upload certificate fingerprints collected
- [ ] Play App Signing certificate fingerprints collected
- [ ] Google Sign-In release configured
- [ ] RevenueCat Android configured
- [ ] Play subscriptions created
- [ ] privacy policy page published
- [ ] account deletion page published
- [ ] Data Safety answers prepared
- [ ] release AAB built
- [ ] internal test uploaded
- [ ] physical-device Android validation passed
