-- Server-side "control center setup completed" flag on profiles.
-- Previously this state lived only in device-local SharedPreferences, so an
-- existing user reinstalling on a NEW device was wrongly re-routed through
-- setup. Storing it on the account makes setup completion follow the user
-- across devices.

alter table public.profiles
  add column if not exists setup_completed boolean not null default false;

-- Backfill: current users are already using the app and have completed setup
-- on their device, so mark them complete to avoid re-onboarding on reinstall.
-- New sign-ups keep the default (false) and go through setup once.
update public.profiles
  set setup_completed = true
  where setup_completed = false;

-- RLS: existing owner select/update policies on public.profiles already cover
-- this column (users read/update only their own row); no new policy required.
