begin;

create or replace function public.delete_my_account_data()
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  table_name text;
  tables text[] := array[
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
    'app_settings'
  ];
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  -- Prevent concurrent deletions for the same user in one transaction window.
  perform pg_advisory_xact_lock(hashtext(auth.uid()::text));

  foreach table_name in array tables loop
    if to_regclass(format('public.%s', table_name)) is not null then
      execute format(
        'delete from public.%I where created_by = auth.uid()',
        table_name
      );
    end if;
  end loop;

  if to_regclass('public.profiles') is not null then
    delete from public.profiles where id = auth.uid();
  end if;
end;
$$;

grant execute on function public.delete_my_account_data() to authenticated;

commit;
