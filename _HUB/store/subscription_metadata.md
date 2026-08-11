# Subscription Metadata — The WakeApp (App Store Connect)

> Ready-to-paste content for the auto-renewable subscriptions in App Store Connect → Subscriptions.
> Brand = **WakeApp**. App Store name = **The WakeApp**. No "AI"/"IA" claims anywhere.
> Positioning: a **personal, customizable control center** — two pillars: **personalization + simplicity**.

---

## 1. Subscription Group

- **Group reference name (internal):** WakeApp Premium
- **Group display name (EN-US):** WakeApp Premium
- **Group display name (FR):** WakeApp Premium

Both products below live in this single group (so users can up/downgrade between monthly and yearly). Entitlement: **premium**.

---

## 2. Product 1 — Monthly

| Field | Value |
|---|---|
| Reference name (internal) | WakeApp Pro Monthly |
| Product ID | `com.wakeapp.pro.monthly` |
| Duration | 1 month |
| Subscription group | WakeApp Premium |
| Entitlement (RevenueCat) | premium |

**Display name (EN-US):** `WakeApp Premium — Monthly`
**Display name (FR):** `WakeApp Premium — Mensuel`

**Description (EN-US):**
> Unlock the full WakeApp control center. Build your own focus setup with unlimited blocking rules, schedules and daily limits, then keep it simple to run every day. Billed monthly, cancel anytime.

**Description (FR):**
> Débloquez tout votre centre de contrôle WakeApp. Composez votre routine focus avec des règles de blocage, des plannings et des limites quotidiennes illimités, puis pilotez tout simplement au quotidien. Facturé chaque mois, annulable à tout moment.

---

## 3. Product 2 — Yearly

| Field | Value |
|---|---|
| Reference name (internal) | WakeApp Pro Yearly |
| Product ID | `com.wakeapp.pro.yearly` |
| Duration | 1 year |
| Subscription group | WakeApp Premium |
| Entitlement (RevenueCat) | premium |

**Display name (EN-US):** `WakeApp Premium — Yearly`
**Display name (FR):** `WakeApp Premium — Annuel`

**Description (EN-US):**
> Get a full year of WakeApp Premium at the best value. Your personal control center, fully customizable and simple to run: unlimited focus sessions, blocking rules, planned pauses and daily limits. Billed once a year, cancel anytime.

**Description (FR):**
> Profitez d'une année complète de WakeApp Premium au meilleur prix. Votre centre de contrôle personnel, entièrement personnalisable et simple à piloter : sessions de focus, règles de blocage, pauses planifiées et limites quotidiennes illimitées. Facturé une fois par an, annulable à tout moment.

---

## 4. Pricing

Prices are set in EUR (ASC sets matching localized prices in other regions automatically).

| Product | Price | Status |
|---|---|---|
| **Monthly** (`com.wakeapp.pro.monthly`) | **2,99 € / mois** | **FIXED** |
| **Yearly** (`com.wakeapp.pro.yearly`) | À DÉCIDER (reco ~19,99 €/an ≈ 2 mois offerts) | À DÉCIDER |

**Monthly is fixed at 2,99 € / mois.** This is the accessible entry price that maximizes installs → paid conversion and fits the 1M-download goal.

**Yearly is not yet fixed.** Recommendation: **À DÉCIDER (reco ~19,99 €/an ≈ 2 mois offerts)** — at 2,99 €/mo, 12 months = 35,88 €, so ~19,99 €/an gives roughly 2 months free (~44% off), a strong incentive to drive yearly subs and reduce churn. Confirm before submitting to App Store Connect.

**Additional levers to decide:**
- **Intro offer / free trial:** recommended **7-day free trial on the yearly plan** to lift conversion. Only claim a trial in copy if the offering actually includes one (Apple rule).
- **Yearly as the highlighted/default plan** on the paywall (better LTV).

---

## 5. Subscription review screenshot text (what the reviewer sees)

Apple requires a screenshot of the paywall for each subscription. Capture the in-app paywall and ensure it visibly shows:

- Product name: **WakeApp Premium**
- Both options: **Monthly** and **Yearly** with localized store prices
- Auto-renewable disclosure: *"Auto-renewable subscription. Cancel anytime in your Apple ID settings."*
- **Restore Purchases**, **Manage Subscription**, **Terms of Use** and **Privacy Policy** links visible
- (If a trial is enabled) the trial duration + "renews automatically unless canceled at least 24 hours before the end of the period."

**Review notes field for each subscription (paste):**
> WakeApp Premium unlocks the full personal control center: unlimited focus sessions, app/website blocking rules, planned pauses, schedules and daily limits. The paywall shows the monthly and yearly options with store-localized prices, auto-renew disclosure, Restore Purchases, Manage Subscription, Terms of Use and Privacy Policy. Billing is handled by the App Store. Premium is required for the Family Controls blocking flows, so please use the provided review account (see App Review Notes) which already has Premium enabled.
