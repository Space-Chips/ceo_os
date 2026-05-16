begin;

-- Remove legacy raw Screen Time logs now that iOS Family Controls data stays
-- on-device only.
drop index if exists public.screen_time_logs_created_by_date_idx;
drop table if exists public.screen_time_logs;

-- Remove stale social Screen Time fields from gamification tables.
alter table if exists public.user_ranks
  drop column if exists screen_time_avg_minutes;

alter table if exists public.leaderboard_entries
  drop column if exists screen_time_avg_minutes;

do $$
declare
  assignments text[];
begin
  if to_regclass('public.advanced_stats_events') is not null then
    execute $sql$
      delete from public.advanced_stats_events
      where event_type in (
        'blocked_app_attempt',
        'blocked_site_attempt',
        'screen_time_recorded',
        'distracting_time_recorded'
      )
    $sql$;
  end if;

  if to_regclass('public.advanced_daily_stats') is not null then
    assignments := array[]::text[];
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_daily_stats'
        and column_name = 'distractions_blocked'
    ) then
      assignments := array_append(assignments, 'distractions_blocked = 0');
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_daily_stats'
        and column_name = 'screen_time_minutes'
    ) then
      assignments := array_append(assignments, 'screen_time_minutes = 0');
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_daily_stats'
        and column_name = 'time_recovered_minutes'
    ) then
      assignments := array_append(assignments, 'time_recovered_minutes = 0');
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_daily_stats'
        and column_name = 'most_distracting_app'
    ) then
      assignments := array_append(assignments, 'most_distracting_app = null');
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_daily_stats'
        and column_name = 'most_distracting_time_window'
    ) then
      assignments := array_append(
        assignments,
        'most_distracting_time_window = null'
      );
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_daily_stats'
        and column_name = 'screen_time_delta_minutes'
    ) then
      assignments := array_append(assignments, 'screen_time_delta_minutes = 0');
    end if;
    if coalesce(array_length(assignments, 1), 0) > 0 then
      execute format(
        'update public.advanced_daily_stats set %s',
        array_to_string(assignments, ', ')
      );
    end if;
  end if;

  if to_regclass('public.advanced_weekly_stats') is not null then
    assignments := array[]::text[];
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_weekly_stats'
        and column_name = 'total_time_recovered_minutes'
    ) then
      assignments := array_append(
        assignments,
        'total_time_recovered_minutes = 0'
      );
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_weekly_stats'
        and column_name = 'total_distractions_blocked'
    ) then
      assignments := array_append(
        assignments,
        'total_distractions_blocked = 0'
      );
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_weekly_stats'
        and column_name = 'total_screen_time_minutes'
    ) then
      assignments := array_append(assignments, 'total_screen_time_minutes = 0');
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_weekly_stats'
        and column_name = 'most_distracting_app'
    ) then
      assignments := array_append(assignments, 'most_distracting_app = null');
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_weekly_stats'
        and column_name = 'most_distracting_time_window'
    ) then
      assignments := array_append(
        assignments,
        'most_distracting_time_window = null'
      );
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_weekly_stats'
        and column_name = 'screen_time_trend'
    ) then
      assignments := array_append(assignments, 'screen_time_trend = 0');
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_weekly_stats'
        and column_name = 'weekly_transformation_delta'
    ) then
      assignments := array_append(
        assignments,
        'weekly_transformation_delta = 0'
      );
    end if;
    if coalesce(array_length(assignments, 1), 0) > 0 then
      execute format(
        'update public.advanced_weekly_stats set %s',
        array_to_string(assignments, ', ')
      );
    end if;
  end if;

  if to_regclass('public.advanced_monthly_stats') is not null then
    assignments := array[]::text[];
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_monthly_stats'
        and column_name = 'total_time_recovered_minutes'
    ) then
      assignments := array_append(
        assignments,
        'total_time_recovered_minutes = 0'
      );
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_monthly_stats'
        and column_name = 'total_screen_time_minutes'
    ) then
      assignments := array_append(assignments, 'total_screen_time_minutes = 0');
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_monthly_stats'
        and column_name = 'lowest_screen_time_day'
    ) then
      assignments := array_append(assignments, 'lowest_screen_time_day = null');
    end if;
    if coalesce(array_length(assignments, 1), 0) > 0 then
      execute format(
        'update public.advanced_monthly_stats set %s',
        array_to_string(assignments, ', ')
      );
    end if;
  end if;

  if to_regclass('public.advanced_lifetime_stats') is not null then
    assignments := array[]::text[];
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_lifetime_stats'
        and column_name = 'total_time_recovered_minutes'
    ) then
      assignments := array_append(
        assignments,
        'total_time_recovered_minutes = 0'
      );
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_lifetime_stats'
        and column_name = 'total_distractions_blocked'
    ) then
      assignments := array_append(
        assignments,
        'total_distractions_blocked = 0'
      );
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_lifetime_stats'
        and column_name = 'lowest_screen_time_ever'
    ) then
      assignments := array_append(assignments, 'lowest_screen_time_ever = 0');
    end if;
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public'
        and table_name = 'advanced_lifetime_stats'
        and column_name = 'life_recovered_days'
    ) then
      assignments := array_append(assignments, 'life_recovered_days = 0');
    end if;
    if coalesce(array_length(assignments, 1), 0) > 0 then
      execute format(
        'update public.advanced_lifetime_stats set %s',
        array_to_string(assignments, ', ')
      );
    end if;
  end if;
end
$$;

commit;
