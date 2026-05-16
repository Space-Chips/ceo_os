-- CEO OS hotfix v3
-- Fixes: missing pareto_tasks.deadline, app_settings slow/inconsistent saves,
-- and leaderboard bootstrap data.

create extension if not exists pgcrypto;

-- 1) Ensure task deadline column exists.
alter table if exists public.pareto_tasks
  add column if not exists deadline timestamptz;
alter table if exists public.pareto_tasks
  add column if not exists description text;

create index if not exists idx_pareto_tasks_deadline on public.pareto_tasks(deadline);

-- 1b) Ensure objectives table exists for habit goals.
create table if not exists public.objectives (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete cascade,
  title text,
  archived boolean not null default false
);

alter table public.objectives enable row level security;
drop policy if exists "objectives_own" on public.objectives;
create policy "objectives_own" on public.objectives
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

-- 2) Ensure app_settings has one row per user for fast updates.
create table if not exists public.app_settings (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete cascade,
  active_apps text[]
);

alter table public.app_settings enable row level security;
drop policy if exists "app_settings_own" on public.app_settings;
create policy "app_settings_own" on public.app_settings
for all to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

-- Deduplicate before adding unique.
delete from public.app_settings t
where t.ctid in (
  select ctid from (
    select ctid,
           row_number() over (partition by created_by order by created_at desc, id desc) as rn
    from public.app_settings
  ) x
  where x.rn > 1
);

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'app_settings_created_by_key'
  ) then
    alter table public.app_settings
      add constraint app_settings_created_by_key unique (created_by);
  end if;
end $$;

-- 3) Leaderboard bootstrap rows.
create table if not exists public.user_ranks (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
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
  created_by uuid not null references auth.users(id) on delete cascade,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  total_completed_sessions int not null default 0,
  total_failed_sessions int not null default 0,
  last_session_date text,
  created_at timestamptz not null default now()
);

create table if not exists public.leaderboard_entries (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  rank_level int not null default 0,
  rank_name text not null default 'Asleep',
  win_streak int not null default 0,
  screen_time_avg_minutes numeric,
  percentile int not null default 0,
  opted_in boolean not null default true,
  last_sync_date timestamptz,
  created_at timestamptz not null default now()
);

-- Deduplicate + unique created_by for upserts.
delete from public.user_ranks t
where t.ctid in (
  select ctid from (
    select ctid, row_number() over (partition by created_by order by created_at desc, id desc) as rn
    from public.user_ranks
  ) x where x.rn > 1
);

delete from public.win_streaks t
where t.ctid in (
  select ctid from (
    select ctid, row_number() over (partition by created_by order by created_at desc, id desc) as rn
    from public.win_streaks
  ) x where x.rn > 1
);

delete from public.leaderboard_entries t
where t.ctid in (
  select ctid from (
    select ctid, row_number() over (partition by created_by order by created_at desc, id desc) as rn
    from public.leaderboard_entries
  ) x where x.rn > 1
);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'user_ranks_created_by_key') then
    alter table public.user_ranks add constraint user_ranks_created_by_key unique (created_by);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'win_streaks_created_by_key') then
    alter table public.win_streaks add constraint win_streaks_created_by_key unique (created_by);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'leaderboard_entries_created_by_key') then
    alter table public.leaderboard_entries add constraint leaderboard_entries_created_by_key unique (created_by);
  end if;
end $$;

insert into public.win_streaks (created_by)
select id from auth.users
on conflict (created_by) do nothing;

insert into public.user_ranks (created_by)
select id from auth.users
on conflict (created_by) do nothing;

insert into public.leaderboard_entries (created_by)
select id from auth.users
on conflict (created_by) do nothing;

-- Optional: recompute if function exists.
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

  v_points := (v_completed_tasks * 7) + (v_completed_habits * 5) + (v_focus_minutes / 10)::int + (v_streak * 18);

  if v_points >= 2500 then
    v_rank_level := 7; v_rank_name := 'Awakened';
  elsif v_points >= 1800 then
    v_rank_level := 6; v_rank_name := 'Immortal';
  elsif v_points >= 1200 then
    v_rank_level := 5; v_rank_name := 'Diamond';
  elsif v_points >= 800 then
    v_rank_level := 4; v_rank_name := 'Platinum';
  elsif v_points >= 450 then
    v_rank_level := 3; v_rank_name := 'Gold';
  elsif v_points >= 200 then
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

do $$
declare
  u record;
  fn_exists boolean;
begin
  select exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'refresh_user_gamification'
  ) into fn_exists;

  if fn_exists then
    for u in select id from auth.users loop
      perform public.refresh_user_gamification(u.id);
    end loop;
  end if;
end $$;
