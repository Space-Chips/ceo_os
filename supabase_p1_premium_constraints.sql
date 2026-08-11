begin;

-- 1) Billing status per user (consumed by Flutter premium checks).
create table if not exists public.billing_subscriptions (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  created_by uuid references auth.users not null,
  status text default 'none' not null,
  provider text default 'manual' not null,
  external_customer_id text,
  external_subscription_id text,
  trial_ends_at timestamptz,
  period_ends_at timestamptz
);

alter table public.billing_subscriptions enable row level security;

drop policy if exists "billing_subscriptions_own" on public.billing_subscriptions;
create policy "billing_subscriptions_own"
  on public.billing_subscriptions
  for all
  using (auth.uid() = created_by)
  with check (auth.uid() = created_by);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'billing_subscriptions_status_check'
  ) then
    alter table public.billing_subscriptions
      add constraint billing_subscriptions_status_check
      check (
        status in ('none', 'inactive', 'active', 'trialing', 'past_due', 'canceled')
      );
  end if;
end $$;

create unique index if not exists billing_subscriptions_created_by_uidx
  on public.billing_subscriptions (created_by);

create index if not exists billing_subscriptions_status_idx
  on public.billing_subscriptions (status);

create index if not exists billing_subscriptions_period_ends_idx
  on public.billing_subscriptions (period_ends_at desc);

create or replace function public.set_billing_subscriptions_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_billing_subscriptions_updated_at on public.billing_subscriptions;
create trigger trg_billing_subscriptions_updated_at
before update on public.billing_subscriptions
for each row
execute function public.set_billing_subscriptions_updated_at();

-- 2) Ensure one global app config key with free_launch_mode toggle.
with ranked as (
  select
    id,
    config_key,
    row_number() over (
      partition by config_key
      order by created_at desc, id desc
    ) as rn
  from public.app_configs
  where config_key is not null
)
delete from public.app_configs c
using ranked r
where c.id = r.id
  and r.rn > 1;

create unique index if not exists app_configs_config_key_uidx
  on public.app_configs (config_key);

insert into public.app_configs (config_key, config_value)
values ('global', '{"free_launch_mode": true}'::jsonb)
on conflict (config_key) do nothing;

update public.app_configs
set config_value = coalesce(config_value, '{}'::jsonb) || '{"free_launch_mode": true}'::jsonb
where config_key = 'global'
  and (
    config_value is null
    or not (coalesce(config_value, '{}'::jsonb) ? 'free_launch_mode')
  );

commit;
