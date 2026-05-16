# Google Play Submission Packet — CEO OS

Date: 2026-03-28  
Project: CEO OS  
Scope: Android publication readiness, Play Console setup, reviewer-facing clarity

## 1. Executive Verdict

### Code-level verdict
**GO**

The Android codebase is now materially cleaner and more publication-ready than before:
- Android package identity has been moved off `com.example.*`
- release signing scaffolding exists
- sensitive permissions are narrower and better justified
- Android permission flows are progressive instead of dumping users into multiple settings at once
- Android wording is now platform-accurate in the app and docs

### Release-level verdict
**NO-GO until the manual blockers below are done**

This is not a code problem anymore.  
It is a release configuration / Play Console / external services problem.

### Operational verdict
- **GO now** for:
  - creating the Play Console app with the final package name
  - preparing listing assets and listing copy
  - preparing App Content / Data Safety answers
  - preparing reviewer-facing disclosures
- **NO-GO now** for:
  - uploading a real release for internal or production testing
  - validating Google Sign-In release
  - validating Google Play Billing / RevenueCat release
  - requesting production publication

Why:
- package identity is now stable in the repo
- but release signing, real Android build validation, and external service wiring are still incomplete

### Operational verdict
- **GO now** for:
  - creating the Play Console app with the final package name
  - preparing listing assets and listing copy
  - preparing App Content / Data Safety answers
  - preparing reviewer-facing disclosures
- **NO-GO now** for:
  - uploading a real release for internal or production testing
  - validating Google Sign-In release
  - validating Google Play Billing / RevenueCat release
  - requesting production publication

Why:
- package identity is now stable in the repo
- but release signing, real Android build validation, and external service wiring are still incomplete

---

## 2. Current Manual Blockers

These are the blockers that still prevent a clean Android publication today.

### B1. Release signing is not fully configured yet
Missing today:
- `android/key.properties`
- upload keystore file

Relevant files:
- [/Users/timo/ceo_os/android/app/build.gradle.kts](/Users/timo/ceo_os/android/app/build.gradle.kts)
- [/Users/timo/ceo_os/android/key.properties.example](/Users/timo/ceo_os/android/key.properties.example)

### B2. Android build has not been verified locally on this machine
The last build attempt here failed because the Android SDK is not configured in the environment:
- `No Android SDK found. Try setting the ANDROID_HOME environment variable.`

This does not mean the project is broken, but it does mean the release path is not yet fully validated on this machine.

### B3. Google Sign-In Android release configuration still needs external setup
The code is now platform-correct, but release setup still requires:
- Android OAuth configuration
- upload certificate fingerprints
- Play App Signing certificate fingerprints
- verification against the Google auth provider / Supabase configuration

Relevant files:
- [/Users/timo/ceo_os/lib/core/config/supabase_config.dart](/Users/timo/ceo_os/lib/core/config/supabase_config.dart)
- [/Users/timo/ceo_os/lib/core/providers/auth_provider.dart](/Users/timo/ceo_os/lib/core/providers/auth_provider.dart)

### B4. RevenueCat + Google Play monetization is not validated yet
Still required:
- Android products in Google Play Console
- base plans / offers if needed
- RevenueCat Android app setup
- product mapping
- webhook validation
- real purchase / restore testing

Relevant files:
- [/Users/timo/ceo_os/lib/core/services/billing_service.dart](/Users/timo/ceo_os/lib/core/services/billing_service.dart)
- [/Users/timo/ceo_os/lib/core/repositories/premium_repository.dart](/Users/timo/ceo_os/lib/core/repositories/premium_repository.dart)
- [/Users/timo/ceo_os/supabase/functions/revenuecat-webhook/index.ts](/Users/timo/ceo_os/supabase/functions/revenuecat-webhook/index.ts)

### B5. Public privacy policy and public account deletion page still need to be verified
Google Play requires:
- a public privacy policy URL
- accurate Data Safety answers
- account deletion support disclosure for apps with account creation

Relevant Google sources:
- [User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)
- [Understanding Google Play’s app account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)

### B6. Real-device Android testing is still required
You still need to validate on a physical Android phone:
- Accessibility flow
- Usage Access flow
- overlay flow
- app blocking
- supported-browser website blocking
- daily limits
- reboot / time-change behavior
- purchase / restore if Premium is enabled

Relevant repo doc:
- [/Users/timo/ceo_os/docs/real_device_test_plan_blocking_stack.md](/Users/timo/ceo_os/docs/real_device_test_plan_blocking_stack.md)

### B7. Play Console declarations are not done yet
Still required:
- Data Safety
- App Content
- Accessibility declaration if prompted
- listing copy
- testing track setup

---

## 3. High-Priority Facts to Keep in Mind

### Target API policy
Google says that **starting August 31, 2025**, new apps and app updates must target **Android 15 / API level 35 or higher** for phones/tablets.  
Source: [Target API level requirements for Google Play apps](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)

### New personal developer accounts
If your Play developer account is a **personal account created after November 13, 2023**, Google requires a **closed test with at least 12 opted-in testers for at least 14 continuous days** before production access.  
Source: [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)

### Accessibility API
Because CEO OS uses `AccessibilityService`, Google requires:
- a Play Console accessibility declaration for non-accessibility-tool use cases
- clear in-app disclosure
- affirmative user consent
- listing documentation of the Accessibility use

Source: [Permissions and APIs that Access Sensitive Information](https://support.google.com/googleplay/android-developer/answer/9888170)

---

## 4. Play Console Checklist — Exact Order

### Step 0. Do not change the package name anymore
Google says package names are unique and permanent, and cannot be deleted or reused later.

For CEO OS, the package name to keep is:
- `com.wakeapp.ceoos`

Source:
- [Create and set up your app](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)

### Step 1. Create the app
In Play Console:
- create the app
- app type: `App`
- free or paid: choose the real business model now
- contact email: support email you will actually monitor

Source: [Create and set up your app](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)

### Step 2. App integrity / signing
- enable Play App Signing
- use a Google-generated app signing key unless you have a strong reason not to
- generate and keep a separate upload key
- add `android/key.properties`
- verify your release bundle signs with the upload key

Source: [Use Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en-EN)

### Step 3. Store listing
Prepare:
- app name
- short description
- full description
- phone screenshots
- feature graphic
- app icon

Constraints from Google:
- app name max 30 chars
- short description max 80 chars
- full description max 4000 chars

Source: [Create and set up your app](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)

### Step 4. App Content
Complete all required sections on the App Content page.
At minimum, expect:
- Privacy Policy
- Data Safety
- Account deletion / Data deletion answers
- Ads declaration
- Target audience / families if relevant
- special declarations if Play prompts them

Recommended order inside Play Console:
1. Privacy Policy
2. Ads
3. App access, if Play review needs credentials
4. Content rating
5. Target audience and content
6. Data Safety
7. Data deletion / account deletion
8. Sensitive permission declarations if surfaced during the flow

Practical note:
- if CEO OS requires login for meaningful review, keep a working reviewer account ready
- if Premium is part of the review surface, keep the reviewer path clear and consistent with Play products

### Step 5. Data Safety
Your answers must match the real app behavior.

For CEO OS, expect at least these data domains to be reviewed carefully:
- account info
- email / auth identifiers
- tasks / habits / notes / focus data
- purchase/subscription state
- app activity / usage-related data if transmitted off-device
- third-party processors: Supabase, Google Sign-In, RevenueCat

Source: [Provide information for Google Play's Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)

Important Google rule:
- Google says all developers with an app published on Google Play must complete the Data Safety form.
- Apps that are only active on the internal testing track are exempt, but once you move beyond that, the form must be accurate and complete.

Implication for CEO OS:
- internal testing can start before the final Data Safety section is fully live
- closed/open/production should not proceed until the Data Safety form is accurate

### Step 6. Privacy Policy
Your privacy policy URL must be:
- public
- active
- non-geofenced
- not a PDF
- labeled clearly as a privacy policy

Source: [User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)

### Step 7. Account deletion
Because the app allows account creation:
- in-app deletion must work
- Play Console data deletion answers must be accurate
- the public deletion support page must exist

Source: [Understanding Google Play’s app account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)

Important Google rule:
- if your app enables account creation, Google requires both:
  - an in-app path to delete the account and associated data
  - a web resource where users can request account deletion and associated data deletion

Implication for CEO OS:
- the in-app flow is already materially improved
- the web deletion page is still a real blocker until it is live and linked in Play Console

### Step 8. Accessibility / sensitive permissions declarations
You must keep the story narrow and factual:
- Accessibility: detect selected distracting apps and supported websites and apply on-device blocking
- Usage Access: evaluate real usage for daily limits
- Overlay: present the blocking shield

Never claim:
- disability support if that is not the true core purpose
- universal website blocking across all browsers
- hidden enforcement
- unrelated analytics use

Source: [Permissions and APIs that Access Sensitive Information](https://support.google.com/googleplay/android-developer/answer/9888170)

Important Google rule:
- sensitive permissions and sensitive APIs must be necessary for current core functionality, disclosed clearly, and requested incrementally
- Google’s updated Accessibility policy language effective **January 28, 2026** specifically reinforces that autonomous initiation/planning/execution of actions is prohibited

Implication for CEO OS:
- the app should be described as user-initiated self-control tooling
- do not describe it like a hidden automation layer or remote enforcement system
- do not claim `isAccessibilityTool=true` unless the app truly qualifies as an accessibility tool for disability support

### Step 9. Monetization
If Premium is live on Android:
- create subscriptions in Play Console
- create base plans
- connect them to RevenueCat
- verify entitlement unlock and restore

### Step 10. Testing tracks
Recommended order:
- internal testing first
- closed testing second if needed
- production only after device validation and policy forms are complete

If your account is under the new personal-account rule:
- satisfy the 12 testers / 14 days requirement before production

Important Google rule:
- for personal developer accounts created after **November 13, 2023**, Google requires a closed test with at least 12 opted-in testers for at least 14 continuous days before production access

Implication for CEO OS:
- if your account is in scope, do not plan for a same-day jump from internal testing to production

### Step 11. Pre-launch and real-device validation
Before production:
- inspect pre-launch report
- run your own real-device test plan
- validate Google Sign-In release
- validate purchases / restore

---

## 5. CEO OS Android Listing Rules

### Safe claims
- Block distracting apps during focus sessions
- Block selected websites on Android in supported browsers
- Apply daily limits to selected apps and supported websites
- Use on-device protection flows for self-control and digital wellbeing

### Unsafe claims
- Blocks every website in every browser
- Impossible to bypass
- Works across all Android web views
- Full parental control over other users' devices
- Accessibility support tool for disability use, unless that is genuinely true

---

## 6. Reviewer Notes Template for Google Play

Use this only if Google Play review asks for clarification:

```text
CEO OS is a personal focus and self-control app.

On Android, the app uses Accessibility to detect when a selected distracting app or supported website is opened, Usage Access to evaluate time spent on selected apps and supported websites for daily-limit enforcement, and display-over-other-apps permission to present the blocking shield.

These Android permissions are used only for the app’s core on-device blocking and self-control features. They are not used for ads, hidden UI manipulation, or unrelated analytics.

Android website blocking depends on what supported browsers expose through the accessibility tree, so CEO OS does not claim universal website blocking across all Android browsers or web views.
```

---

## 7. Final Go / No-Go Gate

### NO-GO if any item below is still false
- [ ] `com.wakeapp.ceoos` is the final Play package you want to keep permanently
- [ ] release keystore exists
- [ ] `android/key.properties` exists locally
- [ ] target SDK resolves to API 35 or higher in the actual Android build
- [ ] Google Sign-In Android release certs are configured
- [ ] RevenueCat Android setup is complete
- [ ] Google Play subscription products exist if Premium is enabled
- [ ] privacy policy URL is live
- [ ] account deletion support URL is live
- [ ] Data Safety answers are prepared and accurate
- [ ] real-device Android blocking test has passed
- [ ] internal testing build succeeds

### GO when all items above are true
At that point, publication becomes an execution task, not a remediation task.

### Practical release states

#### State A — Ready to create the Play app
You are in this state when:
- [x] package name is final
- [x] store-facing product naming is stable enough
- [x] Android sensitive-permission story is coherent

CEO OS status today:
- **YES**

#### State B — Ready for internal testing upload
You are in this state when:
- [ ] release keystore exists
- [ ] `android/key.properties` exists locally
- [ ] a signed Android App Bundle builds successfully
- [ ] Google Sign-In release cert setup is done if sign-in is visible
- [ ] Premium release dependencies are set if Premium is visible

CEO OS status today:
- **NO**

#### State C — Ready for production submission
You are in this state when:
- [ ] internal testing passed
- [ ] real-device validation passed
- [ ] privacy policy URL is live
- [ ] account deletion URL is live
- [ ] Data Safety is accurate
- [ ] required Play declarations are complete
- [ ] closed testing requirement is satisfied if your account is in scope

CEO OS status today:
- **NO**

### Practical release states

#### State A — Ready to create the Play app
You are in this state when:
- [x] package name is final
- [x] store-facing product naming is stable enough
- [x] Android sensitive-permission story is coherent

CEO OS status today:
- **YES**

#### State B — Ready for internal testing upload
You are in this state when:
- [ ] release keystore exists
- [ ] `android/key.properties` exists locally
- [ ] a signed Android App Bundle builds successfully
- [ ] Google Sign-In release cert setup is done if sign-in is visible
- [ ] Premium release dependencies are set if Premium is visible

CEO OS status today:
- **NO**

#### State C — Ready for production submission
You are in this state when:
- [ ] internal testing passed
- [ ] real-device validation passed
- [ ] privacy policy URL is live
- [ ] account deletion URL is live
- [ ] Data Safety is accurate
- [ ] required Play declarations are complete
- [ ] closed testing requirement is satisfied if your account is in scope

CEO OS status today:
- **NO**

---

## 8. My Current Verdict

### Today’s verdict
**Android publication is not yet ready for submission to Google Play production.**

### Why
Not because of the code quality anymore, but because of the remaining external blockers:
- no verified Android release build in this environment
- no release keystore configured yet
- no Play / RevenueCat Android setup verification yet
- no confirmed public privacy/deletion web pages yet
- no real-device Android validation yet

### What to do next
1. Finish external release dependencies  
2. Fill Play Console declarations  
3. Run internal testing  
4. Re-check against this packet  
5. Then submit

### The clearest possible answer
- You can start **Play Console setup now**
- You cannot responsibly start **production submission now**
- You should aim for this order:
  1. create the Play app
  2. configure signing
  3. wire Google Sign-In release and RevenueCat Android
  4. publish privacy policy + deletion page
  5. upload internal test build
  6. validate on a real Android phone
  7. complete App Content / Data Safety / declarations
  8. only then move toward production

### The clearest possible answer
- You can start **Play Console setup now**
- You cannot responsibly start **production submission now**
- You should aim for this order:
  1. create the Play app
  2. configure signing
  3. wire Google Sign-In release and RevenueCat Android
  4. publish privacy policy + deletion page
  5. upload internal test build
  6. validate on a real Android phone
  7. complete App Content / Data Safety / declarations
  8. only then move toward production
