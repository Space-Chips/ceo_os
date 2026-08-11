-- Soft account deletion with a 3-day grace period.
-- The app marks the account for deletion (deletion_scheduled_at = now() + 3 days)
-- and signs the user out. Logging back in within the window lets them cancel.
-- A daily pg_cron job purges accounts whose grace period has elapsed.

-- 1) Schedule columns on the profile (owner RLS already covers updates).
alter table public.profiles
  add column if not exists deletion_scheduled_at timestamptz,
  add column if not exists deletion_reason text;

-- 2) Purge function: permanently deletes every account whose grace period is up.
--    Mirrors the delete-account edge function (storage + app rows + auth user),
--    but runs server-side for ALL due accounts. SECURITY DEFINER so cron (and
--    only cron / admins) can run it.
create or replace function public.purge_scheduled_deletions()
returns integer
language plpgsql
security definer
set search_path = public, auth, storage
as $$
declare
  v_id uuid;
  v_table text;
  v_count integer := 0;
  v_tables text[] := array[
    'habit_completions','habit_logs','habits','calendar_events','pareto_tasks',
    'task_groups','focus_sessions','block_lists','blocked_apps','notes',
    'objectives','screen_time_logs','event_types','leaderboard_entries',
    'friend_connections','weekly_habit_scores','weekly_contracts','user_ranks',
    'win_streaks','user_entitlements','billing_subscriptions','app_settings',
    'family_groups','family_group_members','family_sessions',
    'advanced_weekly_stats','advanced_monthly_stats','advanced_biannual_reports',
    'advanced_stat_snapshots'
  ];
begin
  for v_id in
    select id from public.profiles
    where deletion_scheduled_at is not null
      and deletion_scheduled_at <= now()
  loop
    -- Hard-delete user-owned application rows (skip tables absent in this env).
    foreach v_table in array v_tables loop
      begin
        execute format('delete from public.%I where created_by = $1', v_table) using v_id;
      exception when undefined_table or undefined_column then null;
      end;
    end loop;

    -- Keep the billing audit trail but sever the link to the deleted user.
    begin
      update public.billing_webhook_events set created_by = null where created_by = v_id;
    exception when undefined_table or undefined_column then null;
    end;

    -- Remove user-owned storage objects (avatars/<userId>/...).
    begin
      delete from storage.objects
        where bucket_id = 'avatars' and name like v_id::text || '/%';
    exception when undefined_table then null;
    end;

    -- Remove the profile, then the auth identity last.
    delete from public.profiles where id = v_id;
    delete from auth.users where id = v_id;

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

revoke all on function public.purge_scheduled_deletions() from public, anon, authenticated;

-- 3) Daily cron (03:15 UTC) to run the purge.
create extension if not exists pg_cron;
select cron.unschedule('purge-scheduled-deletions')
  where exists (select 1 from cron.job where jobname = 'purge-scheduled-deletions');
select cron.schedule(
  'purge-scheduled-deletions',
  '15 3 * * *',
  $cron$ select public.purge_scheduled_deletions(); $cron$
);
