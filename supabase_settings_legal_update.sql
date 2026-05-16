begin;

-- Extend app_settings for profile-integrated settings & legal controls.
alter table public.app_settings
  add column if not exists language_code text;

alter table public.app_settings
  add column if not exists notifications_enabled boolean;

alter table public.app_settings
  add column if not exists habit_notifications_enabled boolean;

alter table public.app_settings
  add column if not exists calendar_notifications_enabled boolean;

alter table public.app_settings
  add column if not exists focus_notifications_enabled boolean;

update public.app_settings
set
  language_code = coalesce(language_code, 'en'),
  notifications_enabled = coalesce(notifications_enabled, true),
  habit_notifications_enabled = coalesce(habit_notifications_enabled, true),
  calendar_notifications_enabled = coalesce(calendar_notifications_enabled, true),
  focus_notifications_enabled = coalesce(focus_notifications_enabled, true);

alter table public.app_settings
  alter column language_code set default 'en';
alter table public.app_settings
  alter column notifications_enabled set default true;
alter table public.app_settings
  alter column habit_notifications_enabled set default true;
alter table public.app_settings
  alter column calendar_notifications_enabled set default true;
alter table public.app_settings
  alter column focus_notifications_enabled set default true;

alter table public.app_settings
  alter column language_code set not null;
alter table public.app_settings
  alter column notifications_enabled set not null;
alter table public.app_settings
  alter column habit_notifications_enabled set not null;
alter table public.app_settings
  alter column calendar_notifications_enabled set not null;
alter table public.app_settings
  alter column focus_notifications_enabled set not null;

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'app_settings_language_code_check'
  ) then
    alter table public.app_settings
      drop constraint app_settings_language_code_check;
  end if;

  alter table public.app_settings
    add constraint app_settings_language_code_check
    check (language_code in ('en','fr','zh','hi','es','ar','id','ru','pt'));
end $$;

commit;
