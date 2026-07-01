# WakeApp — iOS Release Build Runbook

Bundle id: `com.wakeapp.ceoos` · Display name: **WakeApp** · Version: `1.0.0+19`
Flutter: `/Users/timo/flutter/bin/flutter`

---

## 1. Secrets / dart-defines

Supabase values are injected at build time via `--dart-define` and read by
`lib/core/config/supabase_config.dart`. A production fallback is embedded for dev
builds, but **release builds must pass the defines explicitly** so the build is
`isConfiguredFromEnvironment == true`.

Required:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Optional (Google sign-in — only if used in this build):
- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_IOS_CLIENT_ID`
- `GOOGLE_ANDROID_CLIENT_ID`

> The anon key is a public client key (safe to ship) but should still be passed via
> define + rotated in the Supabase dashboard if leaked. No service-role/secret key
> is present in the repo — verified.

### Recommended: keep values out of shell history

```bash
export SUPABASE_URL="https://fyjojdynapdaoinpooyd.supabase.co"
export SUPABASE_ANON_KEY="<anon-key-from-supabase-dashboard>"
```

---

## 2. Build commands

Clean + fetch (run once per machine / after dependency changes):

```bash
/Users/timo/flutter/bin/flutter clean
/Users/timo/flutter/bin/flutter pub get
```

### Build the signed App Store archive (IPA)

```bash
/Users/timo/flutter/bin/flutter build ipa --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

Output: `build/ios/ipa/*.ipa` and the archive under `build/ios/archive/`.

If automatic signing is not configured in CI, open the archive in Xcode
(`open ios/Runner.xcworkspace`) → Product ▸ Archive, or use:

```bash
/Users/timo/flutter/bin/flutter build ipa --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --export-options-plist=ios/ExportOptions.plist
```

### Upload to App Store Connect

```bash
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
# or: use Xcode Organizer ▸ Distribute App ▸ App Store Connect
```

---

## 3. Entitlements / capabilities (must be enabled in the App ID + provisioning)

The following targets are built and signed; each needs its capabilities on the
matching App ID in the developer portal:

| Target | Entitlements file | family-controls | App Group(s) |
|---|---|---|---|
| Runner (main app) | `ios/Runner/Runner.entitlements` | ✅ | `group.com.wakeapp.ceoos`, `…ceoos.liveactivity` |
| FocusActivityMonitor | `ios/FocusActivityMonitor/FocusActivityMonitor.entitlements` | ✅ | `group.com.wakeapp.ceoos` |
| ScreenTimeReport | `ios/ScreenTimeReport/ScreenTimeReport.entitlements` | ✅ | `group.com.wakeapp.ceoos` |
| LiveActivityExtension | `ios/LiveActivityExtensionExtension.entitlements` | n/a | `…ceoos`, `…ceoos.liveactivity` |
| CeoWidgets | `ios/CeoWidgetsExtension.entitlements` | n/a | `group.com.wakeapp.ceoos` |

> **Family Controls** is a restricted capability — the App ID(s) must be approved
> by Apple. Confirm the distribution provisioning profiles include
> `com.apple.developer.family-controls` before archiving.
>
> Note: `ios/ShieldAction/` and `ios/ShieldConfiguration/` contain Swift sources but
> are **not registered as Xcode targets** (no entry in `project.pbxproj`). If shield
> UI/action behaviour is required at runtime, these must be added as DeviceActivity /
> ManagedSettingsUI app extensions with their own `.entitlements` carrying
> `family-controls`. Otherwise they are dead source folders.

---

## 4. Pre-submission checklist

- [ ] `pubspec.yaml` version is `1.0.0+19` (bumped from +18).
- [ ] `flutter clean && flutter pub get` run on the build machine.
- [ ] Build invoked with **both** `--dart-define=SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- [ ] `Info.plist` contains `ITSAppUsesNonExemptEncryption = false` (already present →
      no Export Compliance prompt on upload).
- [ ] Usage strings present & honest: `NSCameraUsageDescription`,
      `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`. Live
      Activities: `NSSupportsLiveActivities` + `…FrequentUpdates` = true.
      (Push notifications use the runtime permission prompt — no Info.plist string needed.)
- [ ] All 3 family-controls targets sign with profiles that include the capability.
- [ ] App Groups match across all targets (`group.com.wakeapp.ceoos`).
- [ ] `flutter analyze` → 0 errors (122 info/warning lints, all non-blocking — see QA report).
- [ ] `flutter test` → known stale auth-copy + LanguageProvider test failures triaged
      (4 failing tests are test-harness issues, not app regressions — see QA report).
- [ ] No real secret (service-role key, OAuth client secret) committed — verified.
- [ ] Device smoke test passed (see `real_device_test_checklist.md`).
- [ ] Screenshots, privacy labels, subscription metadata, review notes ready
      (see sibling files in `_HUB/store/`).
