begin;

-- Ensure one app_settings row per user so Flutter upserts on created_by are deterministic.
with ranked as (
  select
    id,
    created_by,
    row_number() over (
      partition by created_by
      order by created_at desc, id desc
    ) as rn
  from public.app_settings
)
delete from public.app_settings s
using ranked r
where s.id = r.id
  and r.rn > 1;

-- Theme + onboarding fields required by onboarding and profile/settings blending.
alter table public.app_settings
  add column if not exists theme_preset text;

alter table public.app_settings
  add column if not exists onboarding_goal text;

alter table public.app_settings
  add column if not exists onboarding_discipline text;

alter table public.app_settings
  add column if not exists onboarding_focus_challenge text;

alter table public.app_settings
  add column if not exists theme_updated_at timestamptz default now();

update public.app_settings
set theme_preset = 'midnight_blue'
where theme_preset is null;

alter table public.app_settings
  alter column theme_preset set default 'midnight_blue';

alter table public.app_settings
  alter column theme_preset set not null;

do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'app_settings_theme_preset_check'
  ) then
    alter table public.app_settings
      drop constraint app_settings_theme_preset_check;
  end if;

  alter table public.app_settings
    add constraint app_settings_theme_preset_check
    check (
      theme_preset in (
        'midnight_blue',
        'graphite',
        'sandstone',
        'deep_forest',
        'light_premium',
        'obsidian_dark',
        'nebula_dark',
        'ember_dark',
        'obsidian_light',
        'nebula_light',
        'ember_light'
      )
    );
end $$;

-- Required for onConflict: 'created_by' writes in Flutter repositories.
create unique index if not exists app_settings_created_by_uidx
  on public.app_settings (created_by);

-- Performance/support indexes for newly exposed pages (rank + screen time manager).
create index if not exists screen_time_logs_created_by_date_idx
  on public.screen_time_logs (created_by, date desc);

create index if not exists user_ranks_created_by_idx
  on public.user_ranks (created_by);

create index if not exists win_streaks_created_by_idx
  on public.win_streaks (created_by);

create unique index if not exists leaderboard_entries_created_by_uidx
  on public.leaderboard_entries (created_by);

commit;
