-- Enable Premium paywall for public release (RevenueCat-backed).
begin;

insert into public.app_configs (config_key, config_value)
values (
  'premium',
  jsonb_build_object(
    'paywall_enabled', true,
    'launch_mode_enabled', false,
    'billing_provider', 'revenuecat',
    'revenuecat_entitlement_id', 'premium',
    'revenuecat_offering_id', 'default'
  )
)
on conflict (config_key) do update
set config_value = coalesce(public.app_configs.config_value, '{}'::jsonb) || excluded.config_value;

commit;
