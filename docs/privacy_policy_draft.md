# Privacy Policy — WakeApp

_Last updated: 28 May 2026_

WakeApp ("we", "us") is operated by The CEO Company. This Privacy Policy explains what personal data we collect when you use the WakeApp iOS application and how we use it.

## 1. Data we collect

| Data | Why | Stored where |
|---|---|---|
| Email address | Account creation, login, password reset, transactional emails | Supabase (EU — Frankfurt, eu-central-1) |
| Account password | Hashed (Argon2) for authentication only | Supabase Auth |
| Display name (optional) | Personalisation of the app | Supabase |
| Subscription / purchase status | To unlock premium features | RevenueCat + Supabase |
| In-app data: tasks, habits, notes, focus sessions, calendar events, goals, screen time logs, friend connections | The core purpose of the app — productivity tracking | Supabase, scoped to your user id by row-level security |
| Selected language | UI localisation | Supabase + on-device |
| Anonymised crash reports | Bug diagnosis | _(if you add Sentry/Crashlytics — disclose here)_ |

We do **not** collect: precise location, contacts, photos (unless you explicitly attach one for your profile), microphone, third-party advertising identifiers.

## 2. Screen Time data (iOS Family Controls)

If you grant Screen Time permission, WakeApp uses Apple's Family Controls API to enforce focus sessions you configure (blocking apps and websites you select). The list of apps and websites stays on your device — Apple's API returns opaque tokens, not human-readable names, and these tokens never leave your phone.

## 3. Lawful bases (GDPR)

- **Performance of a contract**: account, subscription, in-app data
- **Legitimate interest**: crash reports, abuse detection
- **Consent**: optional analytics or marketing emails (you can opt out at any time)

## 4. Service providers

- **Supabase** (Supabase Inc., USA, EU servers): backend database + authentication
- **RevenueCat** (RevenueCat Inc., USA): subscription management
- **Resend** (Resend Inc., USA): transactional emails (signup confirmation, password reset)
- **Apple App Store**: payment processing for subscriptions

All providers operate under EU-US Data Privacy Framework or equivalent SCCs.

## 5. Data retention

- Account + in-app data: until you delete your account (Settings → Delete Account)
- Billing webhook events: 24 months (anonymised after account deletion)
- Logs: 30 days

## 6. Your rights

You can at any time:
- **Access** your data (in-app or by emailing us)
- **Correct** your data (in-app)
- **Delete** your account and all associated data (Settings → Delete Account, which permanently removes all your records from our systems within 7 days)
- **Export** your data (email us at the address below)
- **Withdraw consent** for optional processing

EU users can also lodge a complaint with their national data protection authority.

## 7. Children

WakeApp is not intended for children under 13. We do not knowingly collect data from children. If you believe a child has created an account, contact us and we will delete it.

## 8. Security

Data is encrypted in transit (TLS 1.2+) and at rest (AES-256). Authentication uses PKCE OAuth 2.0. Row-level security ensures one user can never read another user's data.

## 9. Changes

We will notify you in-app or by email at least 14 days before any material change.

## 10. Contact

For any privacy question: **timofrmac@gmail.com**

The CEO Company — France.
