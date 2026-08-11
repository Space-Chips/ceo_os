# App Privacy Labels — The WakeApp (App Store Connect questionnaire)

> Paste-ready answers for App Store Connect → App Privacy ("Nutrition Labels").
> Must match EXACTLY the privacy policy (`docs/privacy_policy_draft.md`, `docs/site_privacy_policy.md`) and the submission packet.
> Source of truth for processors: **Supabase** (DB + Auth, EU Frankfurt), **RevenueCat** (subscriptions), **Apple** (App Store billing), **Resend** (transactional email), **Google Sign-In** (only if user chooses it).

---

## 0. Top-level answer

**Does this app collect data?** → **YES** (the app sends account + productivity data to Supabase/RevenueCat).

Key principle to keep consistent:
- **NOT collected:** Screen Time / Family Controls selections (apps & websites). Apple returns **opaque on-device tokens** that never leave the device → these are **NOT "collected"** for App Privacy purposes. Do **not** list app-blocking selections as collected data.
- **No tracking:** WakeApp does **NOT** use data to track across other companies' apps/sites, no ad identifiers, no data brokers. → Answer **"No"** to the "Used to Track You" section for every type.

---

## 1. Data types collected (declare each below)

### Contact Info → Email Address
- **Collected:** Yes
- **Linked to identity:** Yes
- **Used for tracking:** No
- **Purposes:** App Functionality (account creation, login, password reset), Customer Support (account deletion requests)
- **Processor:** Supabase, Resend (transactional emails)

### Contact Info → Name (Display name, optional)
- **Collected:** Yes
- **Linked to identity:** Yes
- **Used for tracking:** No
- **Purposes:** App Functionality (personalization of the app)
- **Processor:** Supabase

### Identifiers → User ID
- **Collected:** Yes (internal account identifier)
- **Linked to identity:** Yes
- **Used for tracking:** No
- **Purposes:** App Functionality (sync records scoped to the user via row-level security)
- **Processor:** Supabase, RevenueCat (App User ID for entitlement mapping)

### Purchases → Purchase History
- **Collected:** Yes (subscription / entitlement status, product identifiers, purchase & restore state)
- **Linked to identity:** Yes
- **Used for tracking:** No
- **Purposes:** App Functionality (unlock & manage Premium)
- **Processor:** RevenueCat, Apple (App Store billing), mirrored to Supabase

### User Content → Other User Content (productivity records)
- **Collected:** Yes — tasks, habits & completions, notes, planning records, focus sessions, goals, schedules/daily-limit *configuration* (the config metadata, NOT the opaque app tokens)
- **Linked to identity:** Yes
- **Used for tracking:** No
- **Purposes:** App Functionality (core productivity tracking, history & insights, cross-device sync)
- **Processor:** Supabase (row-level security, EU servers)

### Usage Data → Product Interaction
- **Collected:** Yes — focus/daily-limit stats and progress used to display history & insights
- **Linked to identity:** Yes
- **Used for tracking:** No
- **Purposes:** App Functionality (progress/history/insights). NOT analytics for third parties.
- **Processor:** Supabase

### Diagnostics → Crash Data / Performance Data
- **Collected:** **Only if** a crash SDK (Sentry/Crashlytics) is enabled in the shipping build.
- **If enabled:** Collected = Yes, Linked = No (anonymized), Tracking = No, Purpose = App Functionality (bug diagnosis).
- **If NOT enabled in the build → declare "No" / do not list.** ⚠️ FOUNDER: confirm whether a crash reporter ships. Privacy policy lists it as conditional.

---

## 2. Friend connections / Contacts

- The privacy policy mentions "friend connections" as in-app data. These are **in-app social records created inside WakeApp**, NOT the device address book.
- **Do NOT declare the "Contacts" data type** (that is reserved for the device's Contacts/address book, which WakeApp does not access).
- Friend-connection records are covered under **User Content → Other User Content** above (linked, app functionality, no tracking).

---

## 3. Sign in with Google (conditional)

- If Google Sign-In is offered: the email/account identifier returned by Google is covered by **Email Address** + **User ID** above. No additional Google-specific data type needs separate declaration.
- Apple note: if you offer any third-party sign-in (Google), App Store guideline 4.8 requires also offering **Sign in with Apple** OR a privacy-equivalent login (email/password qualifies if it meets 4.8 criteria: limits data to name+email, no advertising, allows keeping email private). ⚠️ FOUNDER: confirm 4.8 compliance before submission.

---

## 4. Data NOT collected (answer "No" — keep consistent with policy)

- Precise or coarse **Location** — No
- **Contacts** (device address book) — No
- **Photos** — No (unless a profile photo is explicitly attached by the user; if that feature ships, declare Photos → Other User Content, Linked, App Functionality, no tracking)
- **Microphone / Audio** — No
- **Advertising identifiers / Ad data** — No
- **Browsing history** — No
- **Screen Time / Family Controls app & website selections** — Not collected (on-device opaque tokens, never transmitted)

---

## 5. Tracking section

- **Does this app use data to track you?** → **No** for all data types.
- No `AppTrackingTransparency` prompt is required if the app genuinely does no cross-app/site tracking and contains no tracking SDKs. ⚠️ Confirm no analytics/ad SDKs are bundled.

---

## 6. Consistency checklist (A4 ↔ A3)

- [ ] Email, Name, User ID, Purchases, User Content, Usage Data declared → matches policy §1/§3
- [ ] Screen Time tokens declared as on-device / NOT collected → matches policy §2/§5/§10
- [ ] Processors listed = Supabase, RevenueCat, Apple, Resend, Google Sign-In → matches policy §4/§8
- [ ] No advertising / no data brokers / no tracking → matches policy §4 ("We do not sell…") 
- [ ] Crash data declared only if SDK actually ships
