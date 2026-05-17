# Google Play Console Field Guide — WakeApp

Date: 2026-03-28  
Project: WakeApp  
Scope: Exact fields, recommended answers, and copy for Play Console setup

## 1. How to Use This Guide

This guide is designed to help you fill Play Console without improvising.

It is intentionally opinionated and optimized for:
- clarity
- policy safety
- consistency with the current Android implementation

If a field is uncertain because it depends on your final business setup, it is marked as:
- `VERIFY BEFORE SUBMITTING`

---

## 2. Assumptions Used in This Guide

This guide assumes:
- the final Android package is `com.wakeapp.ceoos`
- the app name is `WakeApp`
- the default store language is English
- the app has account creation
- the app has no advertising
- Android Premium is intended to be live
- the app is not positioned as an accessibility tool for disability support
- the app is not a Families-targeted kids app

If any of those assumptions are false, update the affected fields before submission.

---

## 3. App Creation

### Field: App name
Recommended value:

`WakeApp`

### Field: Default language
Recommended value:

`English (United States)`  
or your real primary launch language if different

### Field: App or game
Recommended value:

`App`

### Field: Free or paid
Recommended value:

`Free`

Why:
- if you use subscriptions / in-app purchases, the app itself can still be free

### Field: Declarations
Recommended:

Accept only if all information is accurate.

---

## 4. Store Listing

## App details

### App name
Recommended:

`WakeApp`

### Short description
Recommended:

`Focus app with app blocking, website limits, daily limits, and routines.`

This is under the 80-character limit and stays within safe claims.

### Full description
Recommended:

```text
WakeApp is a focus app and personal control center for concentration, discipline, and daily execution. It combines app blocking, website limits, daily limits, routines, tasks, habits, and notes in one place so you can manage your environment more intentionally.

Use WakeApp to:
- block distracting apps during focus sessions
- limit selected websites on Android in supported browsers
- apply daily limits to selected apps and supported websites
- start Focus Mode for protected work sessions
- activate Blackout Mode for stricter focus protection
- schedule pauses and time-based restrictions
- manage routines, tasks, habits, and notes from the same control center

On Android, WakeApp uses on-device protection flows to apply the restrictions you choose. Accessibility is used to detect when a selected distracting app or supported website is opened, Usage Access is used for daily-limit enforcement, and display-over-other-apps permission is used to show the blocking shield.

WakeApp is designed for self-control, productivity, and digital wellbeing. It does not present itself as a disability accessibility tool, and it does not claim universal website blocking across all Android browsers or web views.

Premium features may be offered through subscriptions where available.
```

Why this copy is safe:
- it explains the Android permission story
- it avoids overclaiming
- it mentions supported browsers
- it does not describe hidden enforcement

### App icon
Use the final Android launcher icon / Play icon.

Current repo asset:
- [/Users/timo/ceo_os/android/app/src/main/ic_launcher-playstore.png](/Users/timo/ceo_os/android/app/src/main/ic_launcher-playstore.png)

### Feature graphic
`VERIFY BEFORE SUBMITTING`

Prepare a clean, high-contrast graphic aligned with:
- focus
- self-control
- premium/productivity positioning

Avoid:
- lock imagery that implies absolute device control
- parental surveillance imagery
- claims embedded in the image that overpromise

### Screenshots
Recommended screenshot themes:
1. Focus Mode
2. Blackout Mode
3. Block Apps & Sites
4. Daily limits
5. Habits / planning / task value
6. Privacy / permission clarity if needed

Do not foreground:
- universal website blocking claims
- hidden automation claims
- anything that makes the app look like spyware or parental surveillance

---

## 5. Contact Details

### Support email
Recommended:

Use a monitored support inbox.

Example placeholder:

`INSERT SUPPORT EMAIL`

### Website
Recommended:

Use your public site URL.

Example placeholder:

`INSERT WEBSITE URL`

---

## 6. App Content

## Privacy Policy

### Field: Privacy policy URL
Recommended:

Use the published version of:
- [/Users/timo/ceo_os/docs/site_privacy_policy.md](/Users/timo/ceo_os/docs/site_privacy_policy.md)

The URL must be:
- public
- active
- non-geofenced
- not a PDF

## Ads

### Field: Does your app contain ads?
Recommended:

`No`

Only use `Yes` if the app actually serves ads.

## App access

### Field: Does all or part of your app require login credentials?
Recommended:

`Yes`

Why:
- the meaningful product path appears to rely on an account

### Field: Reviewer instructions
Recommended:

```text
WakeApp requires login to access the main product flows.

Provide a working reviewer test account and password here before submission.

If Premium is part of the review surface, make sure the reviewer path matches the current Android Play Billing configuration.
```

### Field: Additional instructions
Recommended:

```text
On Android, the core blocking flow uses Accessibility, Usage Access, and display-over-other-apps permission. The app explains each permission before sending the user to the relevant Android settings screen.
```

## Content rating

`VERIFY BEFORE SUBMITTING`

Use the official questionnaire truthfully.  
For the current WakeApp product positioning, expect a low rating if there is:
- no violence
- no sexual content
- no gambling
- no user-generated public abuse surface

## Target audience and content

Recommended:

If you want the safest, simplest review path and the app is not built specifically for children:
- do **not** position it as a kids or Families app

Likely recommendation:
- choose adult/general audience ranges that reflect the real product
- avoid claiming child-directed design unless that is truly the product

`VERIFY BEFORE SUBMITTING`

Because this answer affects real policy exposure, make sure it matches your actual intended audience.

---

## 7. Data Safety

Use:
- [/Users/timo/ceo_os/docs/google_play_data_safety_worksheet.md](/Users/timo/ceo_os/docs/google_play_data_safety_worksheet.md)

### Recommended high-level answer direction

#### Does your app collect or share any of the required user data types?
Recommended:

`Yes`

Why:
- account and productivity data are synced
- purchases/subscription data may be processed

#### Is all user data collected by your app encrypted in transit?
Recommended:

`Yes`, if verified in production

`VERIFY BEFORE SUBMITTING`

#### Can users request that their data is deleted?
Recommended:

`Yes`

Why:
- in-app account deletion exists
- web deletion support page is being prepared

### Data categories that likely need careful handling
- Personal info
- Email address
- User IDs
- App activity
- Purchase/subscription status
- Diagnostics, if any release diagnostics are active

### Android sensitive-permission nuance

Accessibility / Usage Access / overlay data should not automatically be described as ad or profiling data.

Use the narrow product story:
- these permissions support on-device blocking and self-control enforcement
- they are not used for advertising
- they are not used for hidden UI manipulation
- they are not used for unrelated analytics

---

## 8. Account Deletion / Data Deletion

### Field: Does your app allow users to create an account?
Recommended:

`Yes`

### Field: Does your app provide a way for users to request account deletion?
Recommended:

`Yes`

### Field: Account deletion URL
Recommended:

Use the published version of:
- [/Users/timo/ceo_os/docs/site_account_deletion.md](/Users/timo/ceo_os/docs/site_account_deletion.md)

### Supporting explanation
Recommended:

```text
Users can delete their account directly inside WakeApp. If they no longer have access to the app, they can request account deletion through the public support page linked here.
```

---

## 9. Sensitive Permissions / Reviewer Explanations

Use these prepared docs:
- [/Users/timo/ceo_os/docs/store_review_notes_and_disclosures.md](/Users/timo/ceo_os/docs/store_review_notes_and_disclosures.md)
- [/Users/timo/ceo_os/docs/google_play_submission_packet.md](/Users/timo/ceo_os/docs/google_play_submission_packet.md)

### Accessibility explanation
Recommended:

```text
WakeApp uses Android Accessibility to detect when a selected distracting app or supported website is opened and to apply the blocking shield on-device. This is a core user-facing feature used for Focus Mode, Blackout Mode, scheduled pauses, and daily-limit enforcement.

WakeApp does not use Accessibility for ads, hidden UI manipulation, or unrelated analytics.
```

### Usage Access explanation
Recommended:

```text
WakeApp uses Usage Access to measure real device usage for selected apps and supported websites so daily limits can be enforced accurately on-device.

WakeApp does not use this access for advertising, profiling, or unrelated analytics.
```

### Overlay explanation
Recommended:

```text
CEO OS uses display-over-other-apps permission to present the blocking shield when a blocked app or supported website is opened. This permission is used only for the app's core focus and restriction features.
```

### Package visibility explanation if Google asks
Recommended:

```text
WakeApp does not rely on broad package visibility for general app inventory. App selection is limited to launcher-visible apps needed for user-facing blocking configuration.
```

### Accessibility tool status
Recommended:

Do **not** claim `isAccessibilityTool = true` unless the app is genuinely an accessibility tool for disability support.

For the current WakeApp positioning:
- recommendation: **No**

---

## 10. Monetization

If Android Premium is live:

### Field: In-app products / subscriptions
Recommended:

Configure only after:
- Play Billing products exist
- RevenueCat Android mapping exists
- test purchase flow is validated

Do not expose broken or unconfigured Android subscriptions in the listing or release.

---

## 11. Testing Tracks

### Internal testing
Recommended:

Use this first.

### Closed testing
Recommended:

Use this next if:
- your account is under the new personal-account rule
- or you want broader validation before production

### Production
Recommended:

Only after:
- signed release build works
- real-device Android validation is passed
- Data Safety is accurate
- privacy/deletion URLs are live
- reviewer account is ready
- Android Premium / sign-in flows are validated if exposed

---

## 12. Submission-Day Mini Checklist

- [ ] Play app created with `com.wakeapp.ceoos`
- [ ] listing fields filled
- [ ] screenshots and feature graphic uploaded
- [ ] privacy policy URL live
- [ ] account deletion URL live
- [ ] Ads declaration done
- [ ] App access reviewer account ready
- [ ] Data Safety answers verified
- [ ] Accessibility/Usage Access/overlay explanations ready
- [ ] internal test bundle uploaded
- [ ] real-device Android test passed
