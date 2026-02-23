# CEO OS Parity Report (CEOV1 -> Flutter Current)

## Scope
This report maps the legacy CEOV1 feature set to the current Flutter app and documents the implemented user flows and production handling.

## Primary User Flow
1. User opens app -> onboarding flow with value proposition slides.
2. User completes onboarding questionnaire (goal, discipline, focus challenge) -> proceeds to signup/login.
3. Authenticated user lands on Home (`/home`) with:
   - dynamic module grid (configurable app modules)
   - quick-add controls for Tasks/Habits/Calendar
   - live dashboard snapshot (tasks/habits/focus/rank)
   - unified focus indicator (single source of truth)
4. User navigates to execution modules (Tasks, Habits, Calendar, Focus) or strategic modules (Insights, Leaderboard, Notes, Rewards, Win Streak, Screen Time, Event Types, Biannual Report).
5. User can configure active modules via App Modules screen (`/app-modules`) and tune Settings (`/settings`).

## CEOV1 -> Current Mapping

| CEOV1 Page | Current Route | Status | Handling |
|---|---|---|---|
| Home | `/home` | Implemented | Dynamic modules + quick-add + insights + profile/menu parity |
| Dashboard | `/stats` | Implemented | Data-driven snapshot + actionable insights |
| Pareto | `/tasks` | Implemented | Priority/backlog/today filtering + calendar sync |
| Habits | `/habits` | Implemented | weekly grid + goals + calendar sync support |
| Calendar | `/calendar` | Implemented | event list + intelligence tab backed by live data |
| FocusMode | `/focus` | Implemented | focus timer, block lists, shield integration |
| Leaderboard | `/leaderboard` | Implemented | rank-level ordering + self highlighting |
| Notes | `/notes` | Implemented | CRUD notes with left list + editor panel |
| WinStreak | `/win-streak` | Implemented | streak stats + weekly habit score history |
| Rewards | `/rewards` | Implemented | weekly contract/reward/sanction configuration |
| ScreenTime / ScreenTimeManager | `/screen-time` + `/focus` | Implemented | log analytics screen + focus management |
| EventTypes | `/event-types` | Implemented | CRUD event type taxonomy |
| BiannualReport | `/biannual-report` | Implemented | 180-day KPI rollup + dominant insight |
| Rank | `/profile` + `/leaderboard` | Implemented | rank metadata in profile and leaderboard |
| Settings | `/settings` | Implemented | profile/focus/system preferences |
| SettingsLanguage/Permissions/Privacy/Terms/Contact/Deletion | `/settings` | Consolidated | consolidated settings experience in Flutter |
| MigrateHabits | `/habits` | Consolidated | migrated habit capabilities in native flows |
| BlockingDemo / FocusModeExit | `/focus` | Consolidated | native flow integrated directly in focus lifecycle |
| CEOMode | Removed | Intentionally removed | replaced by unified focus system |

## Home Experience Parity Details
- Added CEOV1-style active app module control via `/app-modules` + `app_settings.active_apps`.
- Added quick-add affordances from Home for Task/Habit/Calendar.
- Added strategic module surfacing on Home (notes/rewards/win streak/screen time/report/event types).
- Preserved request to remove CEO mode UI.
- Kept one focus indicator while focus mode is active (no duplicate indicators).

## Production Hardening
- Route-level coverage expanded for legacy modules.
- Module configuration persisted in Supabase (`app_settings`).
- Notes/rewards/event-types/win-streak/screen-time use live backend tables with RLS-compatible user scoping.
- Onboarding redesigned with deterministic progression and clear CTA to auth.

## Remaining Consolidations
- Legacy CEOV1 had many micro-settings pages; current app consolidates these under one native Settings screen.
- CEOV1 visual demos (blocking demo) are merged into production focus workflows.
