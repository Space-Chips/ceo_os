-- M-1 fix: enforce free-tier quotas at the database layer so users cannot
-- bypass the client-side checks by calling PostgREST directly.
--
-- Safety design:
--   * Enforcement is gated by a feature flag (app_configs.config_value
--     ->>'server_free_limits_enforced'). It defaults to FALSE so this
--     migration is a no-op until the operator turns it on in the dashboard
--     once they have verified no legitimate user is currently over quota.
--   * The free limits read from the same app_configs row that the client
--     uses, so the client-side UX and the server-side guard stay in sync.
--   * Premium users (active/trialing billing subscription, premium_override,
--     or grandfathered) are completely exempt.

begin;

create or replace function public._wakeapp_is_premium(p_uid uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v boolean := false;
begin
  if p_uid is null then return false; end if;

  -- Active or trialing billing subscription.
  perform 1
  from public.billing_subscriptions
  where created_by = p_uid
    and status in ('active', 'trialing');
  if found then return true; end if;

  -- Entitlement-level overrides / grandfathering.
  select
    coalesce(premium_override, false)
      and (premium_override_expires_at is null
           or premium_override_expires_at > now())
    or coalesce(is_grandfathered, false)
  into v
  from public.user_entitlements
  where created_by = p_uid
  limit 1;

  return coalesce(v, false);
end;
$$;

revoke all on function public._wakeapp_is_premium(uuid) from public;
grant execute on function public._wakeapp_is_premium(uuid) to authenticated, service_role;

create or replace function public._wakeapp_enforcement_enabled()
returns boolean
language sql
stable
as $$
  select coalesce(
    (config_value ->> 'server_free_limits_enforced')::boolean,
    false
  )
  from public.app_configs
  where config_key = 'premium'
  limit 1;
$$;

create or replace function public._wakeapp_free_limit(p_key text, p_default integer)
returns integer
language sql
stable
as $$
  select coalesce(
    nullif(config_value ->> p_key, '')::integer,
    p_default
  )
  from public.app_configs
  where config_key = 'premium'
  limit 1;
$$;

-- Generic enforcer: rejects INSERTs that would push the user above their
-- per-table free quota. The trigger is wired per table with its own
-- (config-key, default) tuple.
create or replace function public._wakeapp_check_free_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_limit integer;
  v_count integer;
  v_config_key text := TG_ARGV[0];
  v_default integer := TG_ARGV[1]::integer;
begin
  if not public._wakeapp_enforcement_enabled() then
    return NEW;
  end if;

  v_uid := NEW.created_by;
  if v_uid is null then
    return NEW;
  end if;

  if public._wakeapp_is_premium(v_uid) then
    return NEW;
  end if;

  v_limit := public._wakeapp_free_limit(v_config_key, v_default);
  if v_limit is null or v_limit <= 0 then
    return NEW;
  end if;

  execute format(
    'select count(*) from public.%I where created_by = $1',
    TG_TABLE_NAME
  ) into v_count using v_uid;

  if v_count >= v_limit then
    raise exception 'Free tier limit reached for %', TG_TABLE_NAME
      using errcode = 'P0001';
  end if;

  return NEW;
end;
$$;

do $$
declare
  spec record;
begin
  for spec in
    select * from (values
      ('pareto_tasks', 'tasks_free_limit', 5),
      ('habits',       'habits_free_limit', 3),
      ('notes',        'notes_free_limit', 50)
    ) as t(tbl, key, default_value)
  loop
    if to_regclass('public.' || spec.tbl) is null then continue; end if;
    execute format(
      'drop trigger if exists trg_%I_free_limit on public.%I',
      spec.tbl, spec.tbl
    );
    execute format(
      'create trigger trg_%I_free_limit
         before insert on public.%I
         for each row execute function public._wakeapp_check_free_limit(%L, %L)',
      spec.tbl, spec.tbl, spec.key, spec.default_value::text
    );
  end loop;
end $$;

commit;

-- Operator note: to turn enforcement on once you have verified no legitimate
-- user is currently above quota, run:
--   update public.app_configs
--   set config_value = coalesce(config_value, '{}'::jsonb)
--     || jsonb_build_object('server_free_limits_enforced', true)
--   where config_key = 'premium';
