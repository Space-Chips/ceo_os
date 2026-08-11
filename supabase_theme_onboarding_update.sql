begin;

-- 1) Ensure one app_settings row per user before adding uniqueness.
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

-- 2) Add theme + onboarding columns.
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

-- 3) Backfill + constraints.
update public.app_settings
set theme_preset = 'midnight_blue'
where theme_preset is null;

alter table public.app_settings
  alter column theme_preset set default 'midnight_blue';

alter table public.app_settings
  alter column theme_preset set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'app_settings_theme_preset_check'
  ) then
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
  end if;
end $$;

-- 4) Enforce one settings row per user for reliable upserts.
create unique index if not exists app_settings_created_by_uidx
  on public.app_settings (created_by);

commit;
