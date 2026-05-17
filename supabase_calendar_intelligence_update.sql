-- Calendar intelligence parity update
-- Adds event duration persistence used by daily/weekly analysis.

begin;

alter table public.calendar_events
  add column if not exists duration_minutes integer not null default 60;

update public.calendar_events
set duration_minutes = 60
where duration_minutes is null or duration_minutes <= 0;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'calendar_events_duration_minutes_chk'
      and conrelid = 'public.calendar_events'::regclass
  ) then
    alter table public.calendar_events
      add constraint calendar_events_duration_minutes_chk
      check (duration_minutes > 0 and duration_minutes <= 1440);
  end if;
end $$;

create index if not exists idx_calendar_events_user_day
  on public.calendar_events(created_by, event_date);

commit;
