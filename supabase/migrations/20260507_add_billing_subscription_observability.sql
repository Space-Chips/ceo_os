-- Billing observability (RevenueCat webhook + support diagnostics)
-- Safe to run multiple times (IF NOT EXISTS).

alter table if exists public.billing_subscriptions
  add column if not exists last_webhook_event_id text;

alter table if exists public.billing_subscriptions
  add column if not exists last_webhook_event_at timestamptz;

alter table if exists public.billing_subscriptions
  add column if not exists last_error text;

alter table if exists public.billing_subscriptions
  add column if not exists last_error_at timestamptz;
