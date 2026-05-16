# CEOV1 -> Flutter Parity Audit (Strict)

Audit date: 2026-03-06  
Method: code-level comparison of every CEOV1 page (`CEOV1/src/pages`) against Flutter routes/screens (`lib/core/router/app_router.dart` + `lib/features/**`), with emphasis on runtime behavior, not only navigation.

## Executive Summary
- Full parity pages: 9/26
- Partial parity pages: 12/26
- Missing/removed pages: 5/26
- Core conclusion: the Flutter app is close on main modules, but **not yet 1:1** with CEOV1 on all mechanisms.

## Page-by-Page Matrix

| CEOV1 page | Flutter target | Status | Notes |
|---|---|---|---|
| Home | `/home` | Partial | Dynamic modules + quick actions + profile/settings/menu present. Visual hierarchy differs from CEOV1 card stack and top chip composition. |
| Dashboard | `/dashboard` | Partial | Action zone + yesterday validation + top tasks/events present. Some CEOV1 micro-behaviors and exact layout pacing differ. |
| Pareto | `/tasks` | Partial | List/matrix/history + CRUD + completion present. CEOV1 premium gate limits are absent. |
| Habits | `/habits` | Partial | Weekly grid + goals + contract + scores present. CEOV1 premium-gating layer absent. |
| Calendar | `/calendar` | Partial | Calendar + intelligence + event type link + add event present. Exact CEOV1 month-tiles visual system and some interaction details differ. |
| FocusMode | `/focus` | Partial | Timer + focus lifecycle + block lists + native shield integration present. CEOV1 premium guard and dedicated early-exit warning flow are not equivalent. |
| FocusModeExit | None dedicated | Missing | No dedicated exit-confirm page matching CEOV1 behavior. |
| CEOMode | None (removed) | Missing | Dedicated irreversible Blackout mode page/logic is not present in Flutter. |
| ScreenTimeManager | `/screen-time-manager` | Full | Hub structure, primary CTA, rank/streak cluster, block/leaderboard/blocking preview actions aligned. |
| ScreenTime | `/screen-time` + `/focus` block lists | Full | Blocked apps/sites CRUD, per-item time extension, and rest-period scheduling/activation now implemented in `/screen-time`. |
| BlockingDemo | None dedicated | Missing | No dedicated demo screen for normal/focus blocking previews. |
| Leaderboard | `/leaderboard` | Full | Global/friends tabs, ranking rows, invite/share, add/remove friend workflows implemented (and stronger than CEOV1). |
| Rank | `/rank` | Partial | Rank screen exists with tiers/position. CEOV1 progression model (focus + CEO hours + long streak thresholds) is not mirrored exactly. |
| WinStreak | `/win-streak` | Partial | Current/longest/sessions + weekly habit scores present. CEOV1 session-history depth is reduced. |
| Rewards | `/rewards` | Full | Weekly contract editing/commit and outcome display present. |
| Notes | `/notes` | Partial | CRUD editor present. CEOV1 tag hierarchy (`#tag/subtag`) and search-centric IA are not fully replicated. |
| EventTypes | `/event-types` | Full | CRUD flow present. |
| BiannualReport | `/biannual-report` | Partial | 180-day summary exists, but CEOV1 multi-axis trends/insights are richer than Flutter’s current compact synthesis. |
| Settings | `/settings` | Consolidated | Settings are blended into profile by design. |
| SettingsLanguage | Profile section | Full | Language picker persisted in `app_settings.language_code`. |
| SettingsPrivacy | Profile section | Full | Legal sheet implemented. |
| SettingsPermissions | Profile section | Full | Permissions policy sheet implemented. |
| SettingsTerms | Profile section | Full | Terms sheet implemented. |
| SettingsContact | Profile section | Full | Contact support sheet implemented. |
| SettingsDeletion | Profile section | Full | Real deletion flow implemented with RPC + fallback deletes. |
| MigrateHabits | None | Missing (low impact) | One-off migration utility page not ported. |

## Critical Gaps To Reach “Identique ou Presque”

1. Blackout Mode parity gap
- CEOV1 has dedicated `CEOMode` with specific constraints; Flutter currently has only unified focus mode.

2. Notes IA gap
- CEOV1 notes supports tag extraction/hierarchy and quick filtering/search-first usage.
- Flutter notes is currently closer to a standard CRUD notes panel.

## Visual Parity Observations (from provided screenshots)

- Strongly aligned now on: neon/glass cards, gradient glows, dense dark texture language for Tasks/Habits/Calendar/ScreenTimeManager.
- Still different on: exact CEOV1 card proportions, icon relief style fidelity in some modules, and CEO-mode dedicated page composition.
- Focus and Dashboard now include atmospheric backdrop alignment pass in Flutter.

## Evidence Anchors (Flutter)

- Routing coverage: `lib/core/router/app_router.dart`
- Theme onboarding + presets (3 dark + 3 light + preview): `lib/features/auth/onboarding_screen.dart`, `lib/core/theme/theme_catalog.dart`, `lib/core/providers/theme_provider.dart`
- Settings merged into profile and functional: `lib/features/settings/settings_screen.dart`, `lib/features/profile/profile_screen.dart`
- Screen time manager actions + blocking preview entry: `lib/features/screen_time_manager/screen_time_manager_screen.dart`
- Focus/block list runtime: `lib/features/focus/focus_screen.dart`, `lib/features/focus/block_list_sheet.dart`, `lib/core/providers/focus_provider.dart`

## Verdict

The app is in an advanced parity state for core navigation and most daily workflows, but it is **not complete parity yet**.  
To claim near-identical CEOV1 behavior, the major remaining work is: Blackout mode parity decision and notes tag/search parity.
