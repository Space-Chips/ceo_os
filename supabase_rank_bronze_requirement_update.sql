-- Update rank defaults and Bronze unlock rule.
-- Bronze requires 7 days in app + 1 completed focus session.
-- Base rank becomes Asleep.

alter table public.user_ranks
  alter column rank_name set default 'Asleep',
  alter column rank_level set default 0;

alter table public.leaderboard_entries
  alter column rank_name set default 'Asleep',
  alter column rank_level set default 0;

create or replace function public.refresh_user_gamification(p_user uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_completed_tasks int := 0;
  v_completed_habits int := 0;
  v_focus_minutes int := 0;
  v_focus_sessions_completed int := 0;
  v_days_in_app int := 0;
  v_points int := 0;
  v_rank_level int := 0;
  v_rank_name text := 'Asleep';
  v_streak int := 0;
  v_total int := 0;
  v_better int := 0;
  v_percentile int := 0;
begin
  select count(*) into v_completed_tasks
  from public.pareto_tasks
  where created_by = p_user and completed = true;

  select count(*) into v_completed_habits
  from public.habit_completions
  where created_by = p_user and completed = true;

  select coalesce(sum(duration_minutes), 0) into v_focus_minutes
  from public.focus_sessions
  where created_by = p_user and completed = true;

  select count(*) into v_focus_sessions_completed
  from public.focus_sessions
  where created_by = p_user and completed = true;

  select coalesce(current_streak, 0) into v_streak
  from public.win_streaks
  where created_by = p_user;

  select greatest(0, (current_date - coalesce(date(created_at), current_date)) + 1)
    into v_days_in_app
  from public.profiles
  where id = p_user;

  v_days_in_app := coalesce(v_days_in_app, 0);

  v_points := (v_completed_tasks * 5)
    + (v_completed_habits * 3)
    + (v_focus_minutes / 10)::int
    + (v_streak * 20);

  if v_points >= 2200 then
    v_rank_level := 7; v_rank_name := 'Awakened';
  elsif v_points >= 1500 then
    v_rank_level := 6; v_rank_name := 'Immortal';
  elsif v_points >= 1000 then
    v_rank_level := 5; v_rank_name := 'Diamond';
  elsif v_points >= 650 then
    v_rank_level := 4; v_rank_name := 'Platinum';
  elsif v_points >= 350 then
    v_rank_level := 3; v_rank_name := 'Gold';
  elsif v_points >= 150 then
    v_rank_level := 2; v_rank_name := 'Silver';
  elsif v_days_in_app >= 7 and v_focus_sessions_completed >= 1 then
    v_rank_level := 1; v_rank_name := 'Bronze';
  else
    v_rank_level := 0; v_rank_name := 'Asleep';
  end if;

  insert into public.user_ranks (created_by, rank_name, rank_level, total_rank_points, win_streak_bonus)
  values (p_user, v_rank_name, v_rank_level, v_points, v_streak)
  on conflict (created_by)
  do update set
    rank_name = excluded.rank_name,
    rank_level = excluded.rank_level,
    total_rank_points = excluded.total_rank_points,
    win_streak_bonus = excluded.win_streak_bonus,
    last_rank_change_date = to_char(now(), 'YYYY-MM-DD');

  insert into public.leaderboard_entries (created_by, rank_level, rank_name, win_streak, last_sync_date)
  values (p_user, v_rank_level, v_rank_name, v_streak, now())
  on conflict (created_by)
  do update set
    rank_level = excluded.rank_level,
    rank_name = excluded.rank_name,
    win_streak = excluded.win_streak,
    last_sync_date = excluded.last_sync_date;

  select count(*) into v_total from public.leaderboard_entries where opted_in = true;

  select count(*) into v_better
  from public.leaderboard_entries
  where opted_in = true and rank_level > v_rank_level;

  if v_total > 0 then
    v_percentile := greatest(1, round(((v_total - v_better)::numeric / v_total::numeric) * 100)::int);
  else
    v_percentile := 0;
  end if;

  update public.leaderboard_entries
  set percentile = v_percentile
  where created_by = p_user;
end;
$$;
