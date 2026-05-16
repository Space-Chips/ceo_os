-- CEO OS production migration
-- Run in Supabase SQL editor as a single script.

create extension if not exists pgcrypto;

-- ─────────────────────────────────────────────────────────────────────────────
-- Profiles
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  avatar_url text,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_user_profile();

alter table public.profiles enable row level security;
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
for select to authenticated
using (auth.uid() = id);
drop policy if exists "profiles_upsert_own" on public.profiles;
create policy "profiles_upsert_own" on public.profiles
for all to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- ─────────────────────────────────────────────────────────────────────────────
-- Task groups + tasks
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.task_groups (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  name text not null,
  color text,
  created_at timestamptz not null default now()
);

create table if not exists public.pareto_tasks (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  importance_level text,
  time_duration text,
  impact_level text,
  sort_order int,
  completed boolean not null default false,
  completed_date timestamptz,
  deadline timestamptz,
  group_id uuid references public.task_groups(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.pareto_tasks add column if not exists group_id uuid references public.task_groups(id) on delete set null;
alter table public.pareto_tasks add column if not exists deadline timestamptz;
alter table public.pareto_tasks add column if not exists completed boolean not null default false;
alter table public.pareto_tasks add column if not exists completed_date timestamptz;
alter table public.pareto_tasks add column if not exists description text;
alter table public.pareto_tasks add column if not exists importance_level text;

alter table public.task_groups enable row level security;
drop policy if exists "task_groups_own" on public.task_groups;
create policy "task_groups_own" on public.task_groups
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

alter table public.pareto_tasks enable row level security;
drop policy if exists "pareto_tasks_own" on public.pareto_tasks;
create policy "pareto_tasks_own" on public.pareto_tasks
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

-- ─────────────────────────────────────────────────────────────────────────────
-- Habits + completions + logs
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  title text not null,
  icon text,
  category text,
  quote text,
  frequency_type text not null default 'daily',
  interval_days int,
  target_type text not null default 'all',
  target_value int,
  target_unit text,
  reminder_time text,
  auto_popup boolean not null default false,
  color_theme text,
  archived boolean not null default false,
  is_daily boolean not null default true,
  specific_days int[],
  created_at timestamptz not null default now()
);

create table if not exists public.habit_completions (
  id uuid primary key default gen_random_uuid(),
  habit_id uuid not null references public.habits(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  date text not null,
  state text,
  completed boolean not null default false,
  checked_in_date timestamptz,
  created_at timestamptz not null default now(),
  unique (habit_id, created_by, date)
);

create table if not exists public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  habit_id uuid not null references public.habits(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  content text not null,
  date text not null,
  created_at timestamptz not null default now()
);

alter table public.habits add column if not exists specific_days int[];

alter table public.habits enable row level security;
drop policy if exists "habits_own" on public.habits;
create policy "habits_own" on public.habits
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

alter table public.habit_completions enable row level security;
drop policy if exists "habit_completions_own" on public.habit_completions;
create policy "habit_completions_own" on public.habit_completions
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

alter table public.habit_logs enable row level security;
drop policy if exists "habit_logs_own" on public.habit_logs;
create policy "habit_logs_own" on public.habit_logs
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

-- ─────────────────────────────────────────────────────────────────────────────
-- Calendar events (manual/task/habit source linkage)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  event_date text,
  event_time text,
  source_type text not null default 'manual',
  source_id uuid,
  recurrence_rule text,
  notification_24h_time timestamptz,
  notification_2h_time timestamptz,
  notification_24h_sent boolean not null default false,
  notification_2h_sent boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.calendar_events add column if not exists source_type text not null default 'manual';
alter table public.calendar_events add column if not exists source_id uuid;
alter table public.calendar_events add column if not exists recurrence_rule text;

alter table public.calendar_events enable row level security;
drop policy if exists "calendar_events_own" on public.calendar_events;
create policy "calendar_events_own" on public.calendar_events
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

-- ─────────────────────────────────────────────────────────────────────────────
-- Focus sessions
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.focus_sessions (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  start_time timestamptz not null,
  end_time timestamptz,
  duration_minutes int not null default 0,
  block_list_id uuid,
  completed boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.focus_sessions enable row level security;
drop policy if exists "focus_sessions_own" on public.focus_sessions;
create policy "focus_sessions_own" on public.focus_sessions
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

-- ─────────────────────────────────────────────────────────────────────────────
-- Goals / Contracts
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.weekly_habit_scores (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  week_start_date text not null,
  week_end_date text not null,
  total_expected int not null default 0,
  total_completed int not null default 0,
  success_percentage int not null default 0,
  threshold_percentage int not null default 90,
  threshold_met boolean not null default false,
  calculated_date timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.weekly_contracts (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  week_start_date text not null,
  week_end_date text not null,
  reward_text text,
  sanction_text text,
  success_threshold_percentage int not null default 90,
  committed boolean not null default false,
  evaluated boolean not null default false,
  outcome_grade text not null default 'pending',
  actual_success_percentage int,
  evaluated_date timestamptz,
  created_at timestamptz not null default now()
);

alter table public.weekly_habit_scores enable row level security;
drop policy if exists "weekly_habit_scores_own" on public.weekly_habit_scores;
create policy "weekly_habit_scores_own" on public.weekly_habit_scores
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

alter table public.weekly_contracts enable row level security;
drop policy if exists "weekly_contracts_own" on public.weekly_contracts;
create policy "weekly_contracts_own" on public.weekly_contracts
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

-- Keep one row per user/week so upserts are deterministic.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'weekly_habit_scores_user_week_key'
  ) then
    alter table public.weekly_habit_scores
    add constraint weekly_habit_scores_user_week_key
    unique (created_by, week_start_date, week_end_date);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'weekly_contracts_user_week_key'
  ) then
    alter table public.weekly_contracts
    add constraint weekly_contracts_user_week_key
    unique (created_by, week_start_date, week_end_date);
  end if;
end $$;

create or replace function public.refresh_weekly_habit_score(
  p_user uuid,
  p_week_start date default (current_date - (extract(isodow from current_date)::int - 1))
)
returns void
language plpgsql
security definer
as $$
declare
  v_week_start date := p_week_start;
  v_week_end date := p_week_start + 6;
  v_total_expected int := 0;
  v_total_completed int := 0;
  v_threshold int := 90;
  v_success int := 0;
begin
  with week_days as (
    select d::date as day, (extract(dow from d)::int) as dow
    from generate_series(v_week_start, v_week_end, interval '1 day') d
  )
  select count(*)
  into v_total_expected
  from public.habits h
  join week_days wd on (
    h.is_daily = true
    or (h.specific_days is not null and wd.dow = any(h.specific_days))
  )
  where h.created_by = p_user and coalesce(h.archived, false) = false;

  select count(*)
  into v_total_completed
  from public.habit_completions hc
  where hc.created_by = p_user
    and hc.completed = true
    and hc.date >= to_char(v_week_start, 'YYYY-MM-DD')
    and hc.date <= to_char(v_week_end, 'YYYY-MM-DD');

  select coalesce(success_threshold_percentage, 90)
  into v_threshold
  from public.weekly_contracts
  where created_by = p_user
    and week_start_date = to_char(v_week_start, 'YYYY-MM-DD')
    and week_end_date = to_char(v_week_end, 'YYYY-MM-DD')
  order by created_at desc
  limit 1;

  if v_total_expected > 0 then
    v_success := round((v_total_completed::numeric / v_total_expected::numeric) * 100)::int;
  else
    v_success := 0;
  end if;

  insert into public.weekly_habit_scores (
    created_by,
    week_start_date,
    week_end_date,
    total_expected,
    total_completed,
    success_percentage,
    threshold_percentage,
    threshold_met,
    calculated_date
  )
  values (
    p_user,
    to_char(v_week_start, 'YYYY-MM-DD'),
    to_char(v_week_end, 'YYYY-MM-DD'),
    v_total_expected,
    v_total_completed,
    v_success,
    v_threshold,
    v_success >= v_threshold,
    now()
  )
  on conflict (created_by, week_start_date, week_end_date)
  do update set
    total_expected = excluded.total_expected,
    total_completed = excluded.total_completed,
    success_percentage = excluded.success_percentage,
    threshold_percentage = excluded.threshold_percentage,
    threshold_met = excluded.threshold_met,
    calculated_date = excluded.calculated_date;
end;
$$;

create or replace function public.after_habit_completion_refresh_weekly_score()
returns trigger
language plpgsql
security definer
as $$
declare
  v_user uuid;
  v_date_text text;
  v_date date;
  v_week_start date;
begin
  if tg_op = 'DELETE' then
    v_user := old.created_by;
    v_date_text := old.date;
  else
    v_user := new.created_by;
    v_date_text := new.date;
  end if;

  v_date := coalesce(to_date(v_date_text, 'YYYY-MM-DD'), current_date);
  v_week_start := v_date - (extract(isodow from v_date)::int - 1);
  perform public.refresh_weekly_habit_score(v_user, v_week_start);
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_habit_completion_weekly_score on public.habit_completions;
create trigger trg_habit_completion_weekly_score
after insert or update or delete on public.habit_completions
for each row execute function public.after_habit_completion_refresh_weekly_score();

-- ─────────────────────────────────────────────────────────────────────────────
-- Gamification: rank + streak + leaderboard
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.user_ranks (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null unique references auth.users(id) on delete cascade,
  rank_name text not null default 'Asleep',
  rank_level int not null default 0,
  screen_time_avg_minutes numeric,
  win_streak_bonus int not null default 0,
  total_rank_points int not null default 0,
  days_at_current_rank int not null default 0,
  previous_rank_name text,
  last_rank_change_date text,
  created_at timestamptz not null default now()
);

create table if not exists public.win_streaks (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null unique references auth.users(id) on delete cascade,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  total_completed_sessions int not null default 0,
  total_failed_sessions int not null default 0,
  last_session_date text,
  created_at timestamptz not null default now()
);

create table if not exists public.leaderboard_entries (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null unique references auth.users(id) on delete cascade,
  rank_level int not null default 0,
  rank_name text not null default 'Asleep',
  win_streak int not null default 0,
  screen_time_avg_minutes numeric,
  percentile int not null default 0,
  opted_in boolean not null default true,
  last_sync_date timestamptz,
  created_at timestamptz not null default now()
);

-- Existing projects may have been created without unique(created_by), which
-- breaks ON CONFLICT (created_by). Deduplicate first, then enforce constraints.
delete from public.user_ranks t
where t.ctid in (
  select ctid from (
    select ctid,
           row_number() over (partition by created_by order by created_at desc, id desc) as rn
    from public.user_ranks
  ) x
  where x.rn > 1
);

delete from public.win_streaks t
where t.ctid in (
  select ctid from (
    select ctid,
           row_number() over (partition by created_by order by created_at desc, id desc) as rn
    from public.win_streaks
  ) x
  where x.rn > 1
);

delete from public.leaderboard_entries t
where t.ctid in (
  select ctid from (
    select ctid,
           row_number() over (partition by created_by order by created_at desc, id desc) as rn
    from public.leaderboard_entries
  ) x
  where x.rn > 1
);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'user_ranks_created_by_key'
  ) then
    alter table public.user_ranks
    add constraint user_ranks_created_by_key unique (created_by);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'win_streaks_created_by_key'
  ) then
    alter table public.win_streaks
    add constraint win_streaks_created_by_key unique (created_by);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'leaderboard_entries_created_by_key'
  ) then
    alter table public.leaderboard_entries
    add constraint leaderboard_entries_created_by_key unique (created_by);
  end if;
end $$;

alter table public.user_ranks enable row level security;
drop policy if exists "user_ranks_read_write_own" on public.user_ranks;
create policy "user_ranks_read_write_own" on public.user_ranks
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

alter table public.win_streaks enable row level security;
drop policy if exists "win_streaks_read_write_own" on public.win_streaks;
create policy "win_streaks_read_write_own" on public.win_streaks
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

alter table public.leaderboard_entries enable row level security;
drop policy if exists "leaderboard_read" on public.leaderboard_entries;
create policy "leaderboard_read" on public.leaderboard_entries
for select to authenticated
using (opted_in = true or auth.uid() = created_by);
drop policy if exists "leaderboard_write_own" on public.leaderboard_entries;
create policy "leaderboard_write_own" on public.leaderboard_entries
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

-- Rank recalculation function
create or replace function public.refresh_user_gamification(p_user uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_completed_tasks int := 0;
  v_completed_habits int := 0;
  v_focus_minutes int := 0;
  v_points int := 0;
  v_focus_sessions_completed int := 0;
  v_days_in_app int := 0;
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

  v_points := (v_completed_tasks * 5) + (v_completed_habits * 3) + (v_focus_minutes / 10)::int + (v_streak * 20);

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

create or replace function public.after_task_rank_refresh()
returns trigger
language plpgsql
security definer
as $$
begin
  perform public.refresh_user_gamification(coalesce(new.created_by, old.created_by));
  return coalesce(new, old);
end;
$$;

create or replace function public.after_habit_rank_refresh()
returns trigger
language plpgsql
security definer
as $$
begin
  perform public.refresh_user_gamification(coalesce(new.created_by, old.created_by));
  return coalesce(new, old);
end;
$$;

create or replace function public.after_focus_rank_refresh()
returns trigger
language plpgsql
security definer
as $$
begin
  perform public.refresh_user_gamification(coalesce(new.created_by, old.created_by));
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_task_rank_refresh on public.pareto_tasks;
create trigger trg_task_rank_refresh
after insert or update or delete on public.pareto_tasks
for each row execute function public.after_task_rank_refresh();

drop trigger if exists trg_habit_rank_refresh on public.habit_completions;
create trigger trg_habit_rank_refresh
after insert or update or delete on public.habit_completions
for each row execute function public.after_habit_rank_refresh();

drop trigger if exists trg_focus_rank_refresh on public.focus_sessions;
create trigger trg_focus_rank_refresh
after insert or update or delete on public.focus_sessions
for each row execute function public.after_focus_rank_refresh();

-- ─────────────────────────────────────────────────────────────────────────────
-- Performance indexes
-- ─────────────────────────────────────────────────────────────────────────────
create index if not exists idx_task_groups_created_by on public.task_groups(created_by);
create index if not exists idx_pareto_tasks_created_by on public.pareto_tasks(created_by);
create index if not exists idx_pareto_tasks_deadline on public.pareto_tasks(deadline);
create index if not exists idx_habits_created_by on public.habits(created_by);
create index if not exists idx_habit_completions_user_date on public.habit_completions(created_by, date);
create index if not exists idx_calendar_events_user_date on public.calendar_events(created_by, event_date);
create index if not exists idx_focus_sessions_user_start on public.focus_sessions(created_by, start_time);
create index if not exists idx_user_ranks_user on public.user_ranks(created_by);
create index if not exists idx_leaderboard_rank on public.leaderboard_entries(rank_level desc);

-- Backfill gamification rows for existing users
insert into public.win_streaks (created_by)
select id from auth.users
on conflict (created_by) do nothing;

insert into public.user_ranks (created_by)
select id from auth.users
on conflict (created_by) do nothing;

insert into public.leaderboard_entries (created_by)
select id from auth.users
on conflict (created_by) do nothing;

-- Recompute all users once
do $$
declare
  u record;
begin
  for u in select id from auth.users loop
    perform public.refresh_user_gamification(u.id);
  end loop;
end $$;
