-- Goal / Contract + ON CONFLICT fix patch
-- Run this once in Supabase SQL editor.

create extension if not exists pgcrypto;

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

-- Keep one row per user/week so upserts work.
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'weekly_habit_scores_user_week_key') then
    alter table public.weekly_habit_scores
    add constraint weekly_habit_scores_user_week_key unique (created_by, week_start_date, week_end_date);
  end if;

  if not exists (select 1 from pg_constraint where conname = 'weekly_contracts_user_week_key') then
    alter table public.weekly_contracts
    add constraint weekly_contracts_user_week_key unique (created_by, week_start_date, week_end_date);
  end if;
end $$;

-- Deduplicate + enforce unique(created_by) for ON CONFLICT in rank tables.
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
  select count(*) into v_total_expected
  from public.habits h
  join week_days wd on (
    h.is_daily = true or (h.specific_days is not null and wd.dow = any(h.specific_days))
  )
  where h.created_by = p_user and coalesce(h.archived, false) = false;

  select count(*) into v_total_completed
  from public.habit_completions hc
  where hc.created_by = p_user
    and hc.completed = true
    and hc.date >= to_char(v_week_start, 'YYYY-MM-DD')
    and hc.date <= to_char(v_week_end, 'YYYY-MM-DD');

  select coalesce(success_threshold_percentage, 90) into v_threshold
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
    created_by, week_start_date, week_end_date,
    total_expected, total_completed, success_percentage,
    threshold_percentage, threshold_met, calculated_date
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
