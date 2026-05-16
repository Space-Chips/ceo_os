-- Family Time feature schema + RLS + RPC
-- Safe to run multiple times.

begin;

create extension if not exists pgcrypto;

create table if not exists public.family_time_groups (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  name text not null,
  invite_token text not null,
  sanction_text text,
  created_at timestamptz not null default now()
);

create table if not exists public.family_time_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.family_time_groups(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  invite_email text,
  display_name text,
  role text not null default 'member',
  quit_points int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.family_time_blocked_apps (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.family_time_groups(id) on delete cascade,
  app_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.family_time_blocked_sites (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.family_time_groups(id) on delete cascade,
  url_domain text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.family_time_sessions (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.family_time_groups(id) on delete cascade,
  started_by uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending',
  duration_minutes int not null default 60,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.family_time_session_participants (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.family_time_sessions(id) on delete cascade,
  member_id uuid not null references public.family_time_members(id) on delete cascade,
  accepted_at timestamptz,
  left_requested_at timestamptz,
  left_at timestamptz,
  left_order int,
  quit_point_awarded boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.family_time_session_events (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.family_time_sessions(id) on delete cascade,
  actor_member_id uuid references public.family_time_members(id) on delete set null,
  event_type text not null,
  message text not null,
  created_at timestamptz not null default now()
);

create unique index if not exists ux_family_time_groups_invite_token_upper
  on public.family_time_groups (upper(invite_token));

create unique index if not exists ux_family_time_members_group_user
  on public.family_time_members (group_id, user_id)
  where user_id is not null;

create unique index if not exists ux_family_time_members_group_invite_email
  on public.family_time_members (group_id, lower(invite_email))
  where invite_email is not null;

create unique index if not exists ux_family_time_blocked_apps_group_name
  on public.family_time_blocked_apps (group_id, lower(app_name));

create unique index if not exists ux_family_time_blocked_sites_group_domain
  on public.family_time_blocked_sites (group_id, lower(url_domain));

create unique index if not exists ux_family_time_session_participants_session_member
  on public.family_time_session_participants (session_id, member_id);

create index if not exists idx_family_time_members_group_id
  on public.family_time_members (group_id);

create index if not exists idx_family_time_sessions_group_created_at
  on public.family_time_sessions (group_id, created_at desc);

create index if not exists idx_family_time_session_events_session_created_at
  on public.family_time_session_events (session_id, created_at desc);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'family_time_members_role_check'
  ) then
    alter table public.family_time_members
      add constraint family_time_members_role_check
      check (role in ('admin', 'member'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'family_time_members_quit_points_non_negative'
  ) then
    alter table public.family_time_members
      add constraint family_time_members_quit_points_non_negative
      check (quit_points >= 0);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'family_time_sessions_status_check'
  ) then
    alter table public.family_time_sessions
      add constraint family_time_sessions_status_check
      check (status in ('pending', 'active', 'completed', 'cancelled'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'family_time_sessions_duration_check'
  ) then
    alter table public.family_time_sessions
      add constraint family_time_sessions_duration_check
      check (duration_minutes between 5 and 240);
  end if;
end;
$$;

create or replace function public.is_family_time_member(
  p_group_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_time_members m
    where m.group_id = p_group_id
      and m.user_id = p_user_id
  );
$$;

create or replace function public.is_family_time_admin(
  p_group_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_time_members m
    where m.group_id = p_group_id
      and m.user_id = p_user_id
      and m.role = 'admin'
  );
$$;

create or replace function public.increment_family_time_quit_points(
  p_member_id uuid
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_points int;
begin
  update public.family_time_members
  set quit_points = quit_points + 1
  where id = p_member_id
    and user_id = auth.uid()
  returning quit_points into v_points;

  if v_points is null then
    raise exception 'Not allowed to increment quit points for this member';
  end if;

  return v_points;
end;
$$;

grant execute on function public.increment_family_time_quit_points(uuid) to authenticated;

alter table public.family_time_groups enable row level security;
alter table public.family_time_members enable row level security;
alter table public.family_time_blocked_apps enable row level security;
alter table public.family_time_blocked_sites enable row level security;
alter table public.family_time_sessions enable row level security;
alter table public.family_time_session_participants enable row level security;
alter table public.family_time_session_events enable row level security;

drop policy if exists "family_time_groups_select_member" on public.family_time_groups;
create policy "family_time_groups_select_member"
on public.family_time_groups
for select
to authenticated
using (
  public.is_family_time_member(id)
  or created_by = auth.uid()
);

drop policy if exists "family_time_groups_insert_owner" on public.family_time_groups;
create policy "family_time_groups_insert_owner"
on public.family_time_groups
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists "family_time_groups_update_admin" on public.family_time_groups;
create policy "family_time_groups_update_admin"
on public.family_time_groups
for update
to authenticated
using (public.is_family_time_admin(id))
with check (public.is_family_time_admin(id));

drop policy if exists "family_time_groups_delete_admin" on public.family_time_groups;
create policy "family_time_groups_delete_admin"
on public.family_time_groups
for delete
to authenticated
using (public.is_family_time_admin(id));

drop policy if exists "family_time_members_select_member" on public.family_time_members;
create policy "family_time_members_select_member"
on public.family_time_members
for select
to authenticated
using (public.is_family_time_member(group_id) or user_id = auth.uid());

drop policy if exists "family_time_members_insert_admin_or_creator_or_self" on public.family_time_members;
create policy "family_time_members_insert_admin_or_creator_or_self"
on public.family_time_members
for insert
to authenticated
with check (
  public.is_family_time_admin(group_id)
  or auth.uid() = user_id
  or auth.uid() = (
    select g.created_by
    from public.family_time_groups g
    where g.id = group_id
  )
);

drop policy if exists "family_time_members_update_admin_or_self_or_invited" on public.family_time_members;
create policy "family_time_members_update_admin_or_self_or_invited"
on public.family_time_members
for update
to authenticated
using (
  public.is_family_time_admin(group_id)
  or user_id = auth.uid()
  or (
    user_id is null
    and lower(coalesce(invite_email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
  )
)
with check (
  public.is_family_time_admin(group_id)
  or user_id = auth.uid()
);

drop policy if exists "family_time_members_delete_admin_or_self" on public.family_time_members;
create policy "family_time_members_delete_admin_or_self"
on public.family_time_members
for delete
to authenticated
using (
  public.is_family_time_admin(group_id)
  or user_id = auth.uid()
);

drop policy if exists "family_time_blocked_apps_select_member" on public.family_time_blocked_apps;
create policy "family_time_blocked_apps_select_member"
on public.family_time_blocked_apps
for select
to authenticated
using (public.is_family_time_member(group_id));

drop policy if exists "family_time_blocked_apps_admin_write" on public.family_time_blocked_apps;
create policy "family_time_blocked_apps_admin_write"
on public.family_time_blocked_apps
for all
to authenticated
using (public.is_family_time_admin(group_id))
with check (public.is_family_time_admin(group_id));

drop policy if exists "family_time_blocked_sites_select_member" on public.family_time_blocked_sites;
create policy "family_time_blocked_sites_select_member"
on public.family_time_blocked_sites
for select
to authenticated
using (public.is_family_time_member(group_id));

drop policy if exists "family_time_blocked_sites_admin_write" on public.family_time_blocked_sites;
create policy "family_time_blocked_sites_admin_write"
on public.family_time_blocked_sites
for all
to authenticated
using (public.is_family_time_admin(group_id))
with check (public.is_family_time_admin(group_id));

drop policy if exists "family_time_sessions_select_member" on public.family_time_sessions;
create policy "family_time_sessions_select_member"
on public.family_time_sessions
for select
to authenticated
using (public.is_family_time_member(group_id));

drop policy if exists "family_time_sessions_insert_admin" on public.family_time_sessions;
create policy "family_time_sessions_insert_admin"
on public.family_time_sessions
for insert
to authenticated
with check (
  public.is_family_time_admin(group_id)
  and started_by = auth.uid()
);

drop policy if exists "family_time_sessions_update_member" on public.family_time_sessions;
create policy "family_time_sessions_update_member"
on public.family_time_sessions
for update
to authenticated
using (public.is_family_time_member(group_id))
with check (public.is_family_time_member(group_id));

drop policy if exists "family_time_sessions_delete_admin" on public.family_time_sessions;
create policy "family_time_sessions_delete_admin"
on public.family_time_sessions
for delete
to authenticated
using (public.is_family_time_admin(group_id));

drop policy if exists "family_time_session_participants_select_member" on public.family_time_session_participants;
create policy "family_time_session_participants_select_member"
on public.family_time_session_participants
for select
to authenticated
using (
  public.is_family_time_member(
    (select s.group_id from public.family_time_sessions s where s.id = session_id)
  )
);

drop policy if exists "family_time_session_participants_insert_admin" on public.family_time_session_participants;
create policy "family_time_session_participants_insert_admin"
on public.family_time_session_participants
for insert
to authenticated
with check (
  public.is_family_time_admin(
    (select s.group_id from public.family_time_sessions s where s.id = session_id)
  )
);

drop policy if exists "family_time_session_participants_update_self_or_admin" on public.family_time_session_participants;
create policy "family_time_session_participants_update_self_or_admin"
on public.family_time_session_participants
for update
to authenticated
using (
  public.is_family_time_admin(
    (select s.group_id from public.family_time_sessions s where s.id = session_id)
  )
  or exists (
    select 1
    from public.family_time_members m
    where m.id = member_id
      and m.user_id = auth.uid()
  )
)
with check (
  public.is_family_time_admin(
    (select s.group_id from public.family_time_sessions s where s.id = session_id)
  )
  or exists (
    select 1
    from public.family_time_members m
    where m.id = member_id
      and m.user_id = auth.uid()
  )
);

drop policy if exists "family_time_session_events_select_member" on public.family_time_session_events;
create policy "family_time_session_events_select_member"
on public.family_time_session_events
for select
to authenticated
using (
  public.is_family_time_member(
    (select s.group_id from public.family_time_sessions s where s.id = session_id)
  )
);

drop policy if exists "family_time_session_events_insert_member" on public.family_time_session_events;
create policy "family_time_session_events_insert_member"
on public.family_time_session_events
for insert
to authenticated
with check (
  public.is_family_time_member(
    (select s.group_id from public.family_time_sessions s where s.id = session_id)
  )
  and (
    actor_member_id is null
    or exists (
      select 1
      from public.family_time_members m
      where m.id = actor_member_id
        and m.user_id = auth.uid()
    )
    or public.is_family_time_admin(
      (select s.group_id from public.family_time_sessions s where s.id = session_id)
    )
  )
);

-- Ensure PostgREST schema cache refresh after DDL changes.
notify pgrst, 'reload schema';

commit;
