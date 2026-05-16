begin;

alter table public.app_settings
  add column if not exists theme_preset text;

update public.app_settings
set theme_preset = 'midnight_blue'
where theme_preset is null;

alter table public.app_settings
  alter column theme_preset set default 'midnight_blue';

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

commit;
