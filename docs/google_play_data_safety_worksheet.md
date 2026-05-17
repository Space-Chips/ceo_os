# Google Play Data Safety Worksheet — WakeApp

Date: 2026-03-28  
Project: WakeApp  
Scope: Working draft to help fill the Google Play Data Safety form accurately

## Important note

This is a product and repo-grounded worksheet, not an official Play export.

Before final submission, confirm every answer against:
- the current production behavior
- enabled third-party SDKs/services
- backend data flows actually live in production

Use this worksheet to reduce guesswork, not to skip verification.

---

## 1. Services involved

Based on the current app architecture, the main processors/services are:
- Supabase
- Google Sign-In, if the user chooses it
- RevenueCat
- Google Play Billing

Relevant files:
- [/Users/timo/ceo_os/lib/core/providers/auth_provider.dart](/Users/timo/ceo_os/lib/core/providers/auth_provider.dart)
- [/Users/timo/ceo_os/lib/core/services/billing_service.dart](/Users/timo/ceo_os/lib/core/services/billing_service.dart)
- [/Users/timo/ceo_os/lib/core/repositories/premium_repository.dart](/Users/timo/ceo_os/lib/core/repositories/premium_repository.dart)

---

## 2. Data types likely in scope

### Collected or transmitted off-device

These are the categories most likely to be declared as collected:
- Personal info
  - email address
  - display name or profile name if used
- App info and performance
  - crash/diagnostic style data if any backend/service receives it
- App activity
  - tasks
  - habits
  - notes
  - focus session records
  - settings/preferences synced to backend
- Financial info
  - purchase/subscription status
- Identifiers
  - account identifiers
  - auth identifiers

### Sensitive Android data that is accessed locally

These are especially sensitive for policy review:
- Accessibility data
- Usage Access data
- overlay-related blocking state

Current product story:
- these are used for on-device enforcement
- they should not be described as ad/profiling/analytics data
- disclosures should stay narrow and factual

---

## 3. Likely answer directions

### Does the app collect data?
Likely: **Yes**

Reason:
- account and app data are transmitted to Supabase
- purchase/subscription data can be processed through RevenueCat / Google Play

### Is all collected data encrypted in transit?
Likely: **Yes**, if every transmitted user data path is HTTPS/TLS in production

You should still verify:
- Supabase endpoints
- RevenueCat endpoints
- Google Sign-In flows

### Can users request that data be deleted?
Likely: **Yes**

Reason:
- the app has in-app account deletion
- Play also requires the public web deletion resource

---

## 4. Data mapping draft

Use this as a working classification draft inside the Play form.

### Personal info
- Email address
  - collected: **Yes**
  - purpose: account management, authentication

### User IDs / identifiers
- Internal account identifier / auth identifier
  - collected: **Yes**
  - purpose: app functionality, account management

### App activity
- Tasks / habits / notes / focus session records
  - collected: **Yes**
  - purpose: app functionality, syncing across sessions/devices, user-requested productivity features

### Financial info
- Purchase or subscription status
  - collected: **Yes**
  - purpose: subscription management, premium access

### App interactions / usage-related data
- Android Usage Access / Accessibility-driven enforcement signals
  - answer carefully
  - if this data remains on-device and is not transmitted off-device, it may not need to be declared as collected
  - if any portion is transmitted or retained server-side, it must be disclosed accurately

Current intended policy-safe story for WakeApp:
- on-device enforcement data is used locally for blocking and daily-limit features
- it is not used for advertising
- it is not used for unrelated profiling

---

## 5. Questions to verify before final submission

These must be answered from the real production configuration:

- Is any crash/analytics SDK active in Android release?
- Is any Android permission-derived usage data transmitted off-device?
- Is any installed-app inventory transmitted off-device?
- Are tasks, habits, notes, and focus sessions synced for every user or optionally?
- Is Google Sign-In visible in Android release?
- Is Premium visible in Android release?

If the answer to any of those changes, update the Data Safety answers.

---

## 6. Safe narrative for reviewer consistency

Use this narrative consistently:

- WakeApp collects ordinary account and productivity data required to provide core app functionality such as authentication, syncing, focus records, tasks, habits, notes, and subscription status.
- On Android, Accessibility, Usage Access, and overlay permissions are used for on-device blocking and self-control enforcement.
- The app does not use those Android protection permissions for ads, hidden UI manipulation, or unrelated analytics.

---

## 7. Final rule

Do not submit the Play Data Safety form from memory.

Before final submission:
- compare this worksheet to the live production setup
- compare it to the public privacy policy
- compare it to the actual Play listing and permission disclosures
