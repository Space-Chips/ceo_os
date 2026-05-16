-- Advanced discipline + attention analytics schema
-- Safe to run multiple times in Supabase SQL editor.

begin;

create extension if not exists pgcrypto;

create or replace function public.set_timestamp_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.advanced_stats_events (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  event_type text not null,
  event_time timestamptz not null,
  source_key text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.advanced_daily_stats (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  date date not null,
  attention_score int not null default 0,
  focus_time_minutes int not null default 0,
  ceo_time_minutes int not null default 0,
  deep_work_time_minutes int not null default 0,
  distractions_blocked int not null default 0,
  distraction_attempts int not null default 0,
  screen_time_minutes int not null default 0,
  productive_time_minutes int not null default 0,
  distracting_time_minutes int not null default 0,
  time_recovered_minutes int not null default 0,
  focus_sessions_completed int not null default 0,
  focus_sessions_broken int not null default 0,
  ceo_sessions_completed int not null default 0,
  ceo_sessions_broken int not null default 0,
  longest_focus_session_minutes int not null default 0,
  longest_ceo_session_minutes int not null default 0,
  habits_planned int not null default 0,
  habits_completed int not null default 0,
  habit_completion_rate numeric(6,5) not null default 0,
  consistency_qualified_day boolean not null default false,
  focus_streak_value int not null default 0,
  ceo_streak_value int not null default 0,
  habit_streak_value int not null default 0,
  full_discipline_qualified_day boolean not null default false,
  rank_at_end_of_day text not null default 'Bronze',
  rank_progress_percent numeric(6,2) not null default 0,
  most_distracting_app text,
  most_distracting_time_window text,
  best_focus_window text,
  worst_focus_window text,
  updated_at timestamptz not null default now()
);

create table if not exists public.advanced_weekly_stats (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  week_start_date date not null,
  week_end_date date not null,
  weekly_attention_score int not null default 0,
  total_focus_time_minutes int not null default 0,
  total_ceo_time_minutes int not null default 0,
  total_deep_work_time_minutes int not null default 0,
  total_time_recovered_minutes int not null default 0,
  total_distractions_blocked int not null default 0,
  total_screen_time_minutes int not null default 0,
  average_focus_session_length_minutes numeric(8,2) not null default 0,
  consistency_percent numeric(6,2) not null default 0,
  completion_rate numeric(6,2) not null default 0,
  best_day_attention_score int not null default 0,
  worst_day_attention_score int not null default 0,
  most_distracting_app text,
  most_distracting_time_window text,
  best_focus_window text,
  percentile numeric(6,2) not null default 0,
  screen_time_trend numeric(8,2) not null default 0,
  weekly_transformation_delta numeric(8,2) not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.advanced_monthly_stats (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  month text not null,
  monthly_attention_score int not null default 0,
  total_focus_time_minutes int not null default 0,
  total_ceo_time_minutes int not null default 0,
  total_deep_work_time_minutes int not null default 0,
  total_time_recovered_minutes int not null default 0,
  total_screen_time_minutes int not null default 0,
  consistency_percent numeric(6,2) not null default 0,
  total_sessions_completed int not null default 0,
  total_sessions_broken int not null default 0,
  total_habits_completed int not null default 0,
  best_week_attention_score int not null default 0,
  lowest_screen_time_day text,
  longest_session_of_month int not null default 0,
  rank_change int not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.advanced_lifetime_stats (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  total_focus_time_minutes int not null default 0,
  total_ceo_time_minutes int not null default 0,
  total_deep_work_time_minutes int not null default 0,
  total_time_recovered_minutes int not null default 0,
  total_distractions_blocked int not null default 0,
  total_focus_sessions_completed int not null default 0,
  total_ceo_sessions_completed int not null default 0,
  total_habits_completed int not null default 0,
  longest_focus_session_minutes int not null default 0,
  longest_ceo_session_minutes int not null default 0,
  best_attention_score_ever int not null default 0,
  lowest_screen_time_ever int not null default 0,
  highest_streak_ever int not null default 0,
  current_rank text not null default 'Bronze',
  milestones_unlocked text[] not null default '{}',
  life_recovered_days numeric(10,2) not null default 0,
  updated_at timestamptz not null default now()
);

create unique index if not exists ux_advanced_stats_events_created_by_source_key
  on public.advanced_stats_events (created_by, source_key)
  where source_key is not null;

create index if not exists idx_advanced_stats_events_created_by_event_time
  on public.advanced_stats_events (created_by, event_time desc);

create index if not exists idx_advanced_stats_events_event_type
  on public.advanced_stats_events (created_by, event_type, event_time desc);

create unique index if not exists ux_advanced_daily_stats_created_by_date
  on public.advanced_daily_stats (created_by, date);

create index if not exists idx_advanced_daily_stats_created_by_date_desc
  on public.advanced_daily_stats (created_by, date desc);

create unique index if not exists ux_advanced_weekly_stats_created_by_week_start
  on public.advanced_weekly_stats (created_by, week_start_date);

create unique index if not exists ux_advanced_monthly_stats_created_by_month
  on public.advanced_monthly_stats (created_by, month);

create unique index if not exists ux_advanced_lifetime_stats_created_by
  on public.advanced_lifetime_stats (created_by);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_stats_events_event_type_check'
  ) then
    alter table public.advanced_stats_events
      add constraint advanced_stats_events_event_type_check
      check (
        event_type in (
          'focus_session_started',
          'focus_session_completed',
          'focus_session_broken',
          'ceo_session_started',
          'ceo_session_completed',
          'ceo_session_broken',
          'blocked_app_attempt',
          'blocked_site_attempt',
          'screen_time_recorded',
          'productive_time_recorded',
          'distracting_time_recorded',
          'habit_planned',
          'habit_completed',
          'habit_missed',
          'rank_changed',
          'manual_time_extension_requested',
          'manual_time_extension_confirmed',
          'dashboard_opened',
          'note_created_during_focus'
        )
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_daily_stats_attention_score_check'
  ) then
    alter table public.advanced_daily_stats
      add constraint advanced_daily_stats_attention_score_check
      check (attention_score between 0 and 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_daily_stats_habit_completion_rate_check'
  ) then
    alter table public.advanced_daily_stats
      add constraint advanced_daily_stats_habit_completion_rate_check
      check (habit_completion_rate between 0 and 1);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_daily_stats_rank_progress_percent_check'
  ) then
    alter table public.advanced_daily_stats
      add constraint advanced_daily_stats_rank_progress_percent_check
      check (rank_progress_percent between 0 and 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_weekly_stats_score_check'
  ) then
    alter table public.advanced_weekly_stats
      add constraint advanced_weekly_stats_score_check
      check (weekly_attention_score between 0 and 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_weekly_stats_consistency_percent_check'
  ) then
    alter table public.advanced_weekly_stats
      add constraint advanced_weekly_stats_consistency_percent_check
      check (consistency_percent between 0 and 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_weekly_stats_completion_rate_check'
  ) then
    alter table public.advanced_weekly_stats
      add constraint advanced_weekly_stats_completion_rate_check
      check (completion_rate between 0 and 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_weekly_stats_percentile_check'
  ) then
    alter table public.advanced_weekly_stats
      add constraint advanced_weekly_stats_percentile_check
      check (percentile between 0 and 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_weekly_stats_week_range_check'
  ) then
    alter table public.advanced_weekly_stats
      add constraint advanced_weekly_stats_week_range_check
      check (week_end_date >= week_start_date);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_monthly_stats_score_check'
  ) then
    alter table public.advanced_monthly_stats
      add constraint advanced_monthly_stats_score_check
      check (monthly_attention_score between 0 and 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_monthly_stats_consistency_percent_check'
  ) then
    alter table public.advanced_monthly_stats
      add constraint advanced_monthly_stats_consistency_percent_check
      check (consistency_percent between 0 and 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_monthly_stats_month_format_check'
  ) then
    alter table public.advanced_monthly_stats
      add constraint advanced_monthly_stats_month_format_check
      check (month ~ '^[0-9]{4}-[0-9]{2}$');
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'advanced_lifetime_stats_best_attention_score_ever_check'
  ) then
    alter table public.advanced_lifetime_stats
      add constraint advanced_lifetime_stats_best_attention_score_ever_check
      check (best_attention_score_ever between 0 and 100);
  end if;
end;
$$;

drop trigger if exists trg_advanced_daily_stats_updated_at on public.advanced_daily_stats;
create trigger trg_advanced_daily_stats_updated_at
before update on public.advanced_daily_stats
for each row execute function public.set_timestamp_updated_at();

drop trigger if exists trg_advanced_weekly_stats_updated_at on public.advanced_weekly_stats;
create trigger trg_advanced_weekly_stats_updated_at
before update on public.advanced_weekly_stats
for each row execute function public.set_timestamp_updated_at();

drop trigger if exists trg_advanced_monthly_stats_updated_at on public.advanced_monthly_stats;
create trigger trg_advanced_monthly_stats_updated_at
before update on public.advanced_monthly_stats
for each row execute function public.set_timestamp_updated_at();

drop trigger if exists trg_advanced_lifetime_stats_updated_at on public.advanced_lifetime_stats;
create trigger trg_advanced_lifetime_stats_updated_at
before update on public.advanced_lifetime_stats
for each row execute function public.set_timestamp_updated_at();

alter table public.advanced_stats_events enable row level security;
alter table public.advanced_daily_stats enable row level security;
alter table public.advanced_weekly_stats enable row level security;
alter table public.advanced_monthly_stats enable row level security;
alter table public.advanced_lifetime_stats enable row level security;

drop policy if exists "advanced_stats_events_own" on public.advanced_stats_events;
create policy "advanced_stats_events_own"
on public.advanced_stats_events
for all
to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

drop policy if exists "advanced_daily_stats_own" on public.advanced_daily_stats;
create policy "advanced_daily_stats_own"
on public.advanced_daily_stats
for all
to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

drop policy if exists "advanced_weekly_stats_own" on public.advanced_weekly_stats;
create policy "advanced_weekly_stats_own"
on public.advanced_weekly_stats
for all
to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

drop policy if exists "advanced_monthly_stats_own" on public.advanced_monthly_stats;
create policy "advanced_monthly_stats_own"
on public.advanced_monthly_stats
for all
to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

drop policy if exists "advanced_lifetime_stats_own" on public.advanced_lifetime_stats;
create policy "advanced_lifetime_stats_own"
on public.advanced_lifetime_stats
for all
to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

commit;
