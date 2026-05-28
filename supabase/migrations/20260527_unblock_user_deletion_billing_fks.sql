-- 20260527_unblock_user_deletion_billing_fks.sql
--
-- WHY
-- ---
-- Deleting a row from `auth.users` was rejected by Postgres because three
-- billing/entitlement tables hold an orphaned foreign key to `auth.users(id)`
-- without an `ON DELETE` clause. Postgres defaults to `NO ACTION`, which
-- aborts the delete if dependent rows exist.
--
-- Affected FKs (legacy migrations):
--   - public.billing_webhook_events.created_by  -> auth.users
--       (supabase_billing_revenuecat_v4.sql:43)
--   - public.user_entitlements.created_by       -> auth.users (not null unique)
--       (supabase_premium_foundation_v2.sql:42)
--   - public.billing_subscriptions.created_by   -> auth.users (not null)
--       (supabase_p1_premium_constraints.sql:8)
--
-- POLICY
-- ------
--   billing_webhook_events.created_by -> ON DELETE SET NULL
--       Webhook events are an audit trail (provider deliveries, retries).
--       We must keep historical events even after a user is deleted, so we
--       null out the foreign key. The `created_by` column is already nullable.
--
--   user_entitlements.created_by      -> ON DELETE CASCADE
--       Entitlements have no value once the user is gone.
--
--   billing_subscriptions.created_by  -> ON DELETE CASCADE
--       Subscription rows are user-scoped; reissue or backfill if needed.
--       RevenueCat remains the source of truth for billing history.
--
-- This migration is idempotent: it drops the current FK constraint by name
-- (auto-generated `<table>_<column>_fkey` per Postgres convention) only if
-- present, then recreates it with the desired `ON DELETE` policy.

begin;

do $$
declare
  v_existing text;
begin
  -- 1) billing_webhook_events.created_by → SET NULL
  if to_regclass('public.billing_webhook_events') is not null then
    select conname into v_existing
    from pg_constraint
    where conrelid = 'public.billing_webhook_events'::regclass
      and contype = 'f'
      and (
        conname = 'billing_webhook_events_created_by_fkey'
        or conname like '%created_by%fkey%'
      )
    limit 1;
    if v_existing is not null then
      execute format(
        'alter table public.billing_webhook_events drop constraint %I',
        v_existing
      );
    end if;
    alter table public.billing_webhook_events
      add constraint billing_webhook_events_created_by_fkey
      foreign key (created_by)
      references auth.users(id)
      on delete set null;
  end if;

  -- 2) user_entitlements.created_by → CASCADE
  if to_regclass('public.user_entitlements') is not null then
    select conname into v_existing
    from pg_constraint
    where conrelid = 'public.user_entitlements'::regclass
      and contype = 'f'
      and (
        conname = 'user_entitlements_created_by_fkey'
        or conname like '%created_by%fkey%'
      )
    limit 1;
    if v_existing is not null then
      execute format(
        'alter table public.user_entitlements drop constraint %I',
        v_existing
      );
    end if;
    alter table public.user_entitlements
      add constraint user_entitlements_created_by_fkey
      foreign key (created_by)
      references auth.users(id)
      on delete cascade;
  end if;

  -- 3) billing_subscriptions.created_by → CASCADE
  if to_regclass('public.billing_subscriptions') is not null then
    select conname into v_existing
    from pg_constraint
    where conrelid = 'public.billing_subscriptions'::regclass
      and contype = 'f'
      and (
        conname = 'billing_subscriptions_created_by_fkey'
        or conname like '%created_by%fkey%'
      )
    limit 1;
    if v_existing is not null then
      execute format(
        'alter table public.billing_subscriptions drop constraint %I',
        v_existing
      );
    end if;
    alter table public.billing_subscriptions
      add constraint billing_subscriptions_created_by_fkey
      foreign key (created_by)
      references auth.users(id)
      on delete cascade;
  end if;
end
$$;

commit;
