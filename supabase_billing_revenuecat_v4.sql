begin;

insert into public.app_configs (config_key, config_value)
values (
  'premium',
  jsonb_build_object(
    'billing_provider', 'revenuecat',
    'revenuecat_ios_api_key', '',
    'revenuecat_android_api_key', '',
    'revenuecat_entitlement_id', 'premium',
    'revenuecat_offering_id', 'default'
  )
)
on conflict (config_key) do update
set config_value = coalesce(public.app_configs.config_value, '{}'::jsonb) || excluded.config_value;

alter table public.billing_subscriptions
  add column if not exists product_id text,
  add column if not exists price_id text,
  add column if not exists period_starts_at timestamptz,
  add column if not exists canceled_at timestamptz,
  add column if not exists is_founding_plan boolean default false not null,
  add column if not exists provider_payload jsonb,
  add column if not exists last_synced_at timestamptz;

alter table public.billing_subscriptions enable row level security;

drop policy if exists "billing_subscriptions_own" on public.billing_subscriptions;
drop policy if exists "billing_subscriptions_select_own" on public.billing_subscriptions;

create policy "billing_subscriptions_select_own"
  on public.billing_subscriptions
  for select
  to authenticated
  using (auth.uid() = created_by);

create table if not exists public.billing_webhook_events (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now() not null,
  provider text not null,
  event_id text not null,
  event_type text,
  created_by uuid references auth.users,
  payload jsonb not null
);

create unique index if not exists billing_webhook_events_provider_event_uidx
  on public.billing_webhook_events (provider, event_id);

alter table public.billing_webhook_events enable row level security;

drop policy if exists "billing_webhook_events_none" on public.billing_webhook_events;
create policy "billing_webhook_events_none"
  on public.billing_webhook_events
  for select
  to authenticated
  using (false);

commit;
