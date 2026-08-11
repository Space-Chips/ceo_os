-- Fix "Failed to delete user: Database error deleting user" in Supabase Dashboard.
-- Common causes are FK constraints (including storage.objects owner FK) and missing cascades.
-- This migration:
-- 1) Makes storage.objects owner FK non-blocking (ON DELETE SET NULL) so users can be deleted.
-- 2) Adds a BEFORE DELETE trigger on auth.users that deletes WakeApp-owned rows by user id.

-- 1) Storage: prevent objects_owner_fkey from blocking user deletion.
do $$
begin
  if to_regclass('storage.objects') is not null then
    begin
      -- Drop if present (name may vary by project; the default is objects_owner_fkey).
      execute 'alter table storage.objects drop constraint if exists objects_owner_fkey';
    exception when others then
      -- Best effort only.
      null;
    end;

    begin
      execute 'alter table storage.objects add constraint objects_owner_fkey foreign key (owner) references auth.users(id) on delete set null';
    exception when others then
      -- If the constraint already exists under another name, ignore.
      null;
    end;
  end if;
end $$;

-- 2) WakeApp cleanup trigger.
create or replace function public._wakeapp_delete_user_data(p_uid uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  t text;
  deletable_tables text[] := array[
    'habit_completions',
    'habit_logs',
    'habits',
    'calendar_events',
    'pareto_tasks',
    'task_groups',
    'focus_sessions',
    'block_lists',
    'blocked_apps',
    'notes',
    'objectives',
    'screen_time_logs',
    'event_types',
    'leaderboard_entries',
    'friend_connections',
    'weekly_habit_scores',
    'weekly_contracts',
    'user_ranks',
    'win_streaks',
    'user_entitlements',
    'billing_subscriptions',
    'app_settings',
    'billing_webhook_events',
    'family_groups',
    'family_group_members',
    'family_sessions',
    'advanced_weekly_stats',
    'advanced_monthly_stats',
    'advanced_biannual_reports',
    'advanced_stat_snapshots'
  ];
begin
  foreach t in array deletable_tables loop
    if to_regclass('public.' || t) is not null then
      execute format('delete from public.%I where created_by = $1', t) using p_uid;
    end if;
  end loop;

  if to_regclass('public.profiles') is not null then
    execute 'delete from public.profiles where id = $1' using p_uid;
  end if;

  -- Extra safety: dynamically remove rows in any table that has a `created_by`
  -- column matching this user id (covers future tables without updating lists).
  for t in
    select quote_ident(table_schema) || '.' || quote_ident(table_name)
    from information_schema.columns
    where column_name = 'created_by'
      and table_schema in ('public')
  loop
    execute format('delete from %s where created_by = $1', t) using p_uid;
  end loop;
end;
$$;

create or replace function public._wakeapp_before_auth_user_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._wakeapp_delete_user_data(old.id);
  return old;
end;
$$;

drop trigger if exists wakeapp_before_auth_user_delete on auth.users;
create trigger wakeapp_before_auth_user_delete
before delete on auth.users
for each row execute procedure public._wakeapp_before_auth_user_delete();
