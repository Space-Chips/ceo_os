-- C0-1 fix: enable RLS on public.app_configs.
-- Reads must remain available to anon + authenticated clients
-- (mobile SDK keys, paywall flags, free-tier limits are all read by the app at startup).
-- Writes are reserved to service_role (no policy is created for INSERT/UPDATE/DELETE).

alter table if exists public.app_configs enable row level security;

drop policy if exists "app_configs_select_public" on public.app_configs;
create policy "app_configs_select_public"
  on public.app_configs
  for select
  to anon, authenticated
  using (true);

-- Defensive: revoke any pre-existing write grants that may have leaked in dev.
do $$
begin
  if to_regclass('public.app_configs') is not null then
    execute 'revoke insert, update, delete on public.app_configs from anon';
    execute 'revoke insert, update, delete on public.app_configs from authenticated';
  end if;
end $$;
