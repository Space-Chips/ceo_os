begin;

create unique index if not exists app_configs_config_key_uidx
  on public.app_configs (config_key);

insert into public.app_configs (config_key, config_value)
values (
  'premium',
  jsonb_build_object(
    'launch_mode_enabled', true,
    'launch_started_at', '2026-03-20T00:00:00+01:00',
    'launch_ends_at', '2026-04-20T00:00:00+02:00',
    'paywall_enabled', false,
    'launch_premium_labels_enabled', true,
    'grandfathering_enabled', true,
    'early_discount_enabled', true,
    'tasks_free_limit', 5,
    'habits_free_limit', 3,
    'notes_free_limit', 50,
    'focus_free_daily_limit', 1,
    'focus_free_max_duration_minutes', 30,
    'ceo_free_weekly_limit', 1,
    'ceo_free_max_duration_minutes', 60,
    'free_themes', jsonb_build_array(
      'carbon_system',
      'ember_protocol',
      'cloud_studio'
    ),
    'premium_themes', jsonb_build_array(
      'modern_desert',
      'royal_violet'
    )
  )
)
on conflict (config_key) do update
set config_value = coalesce(public.app_configs.config_value, '{}'::jsonb) || excluded.config_value;

create table if not exists public.user_entitlements (
  id uuid default gen_random_uuid() primary key,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  created_by uuid references auth.users not null unique,
  early_launch_user boolean default false not null,
  early_launch_qualified_at timestamptz,
  is_grandfathered boolean default false not null,
  grandfather_reason text,
  theme_bundle_granted boolean default false not null,
  theme_bundle_source text,
  discount_eligible boolean default false not null,
  discount_kind text,
  discount_percent integer,
  discount_price_id text,
  badge_code text,
  premium_override boolean default false not null,
  premium_override_reason text,
  premium_override_expires_at timestamptz
);

alter table public.user_entitlements enable row level security;

drop policy if exists "user_entitlements_own" on public.user_entitlements;
create policy "user_entitlements_own"
  on public.user_entitlements
  for all
  using (auth.uid() = created_by)
  with check (auth.uid() = created_by);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'user_entitlements_discount_percent_check'
  ) then
    alter table public.user_entitlements
      add constraint user_entitlements_discount_percent_check
      check (
        discount_percent is null
        or (discount_percent >= 0 and discount_percent <= 100)
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'user_entitlements_discount_kind_check'
  ) then
    alter table public.user_entitlements
      add constraint user_entitlements_discount_kind_check
      check (
        discount_kind is null
        or discount_kind in ('percentage', 'price_id', 'founding_price')
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'user_entitlements_badge_code_check'
  ) then
    alter table public.user_entitlements
      add constraint user_entitlements_badge_code_check
      check (
        badge_code is null
        or badge_code in ('early_user', 'founding_member')
      );
  end if;
end $$;

create index if not exists user_entitlements_created_by_idx
  on public.user_entitlements (created_by);

create or replace function public.set_user_entitlements_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_user_entitlements_updated_at on public.user_entitlements;
create trigger trg_user_entitlements_updated_at
before update on public.user_entitlements
for each row
execute function public.set_user_entitlements_updated_at();

commit;
