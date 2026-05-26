# Security Operations Checklist

Companion to [SECURITY_REVIEW_2026-05-25.md](../SECURITY_REVIEW_2026-05-25.md). The items below cannot be fixed via code alone — they require dashboard / pipeline / App Store Connect actions.

## 1. Supabase Edge Functions — secrets to set

The webhook now refuses to boot without `REVENUECAT_WEBHOOK_AUTH`. Set it before deploying the updated functions:

```
supabase secrets set REVENUECAT_WEBHOOK_AUTH=$(openssl rand -hex 32) \
  --env-file .env.functions
```

Then deploy:

```
supabase functions deploy revenuecat-webhook
supabase functions deploy grant-beta-premium
supabase functions deploy delete-account
```

Required secrets per function (verify in Supabase Dashboard → Functions → *function* → Secrets):

| Function | Required secrets |
|---|---|
| `revenuecat-webhook` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `REVENUECAT_WEBHOOK_AUTH` |
| `grant-beta-premium` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` |
| `delete-account` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY` |

## 2. RevenueCat dashboard — webhook authentication

In RevenueCat Dashboard → Project Settings → Integrations → Webhooks:

- URL: `https://<project>.supabase.co/functions/v1/revenuecat-webhook`
- Authorization Header: `Bearer <value of REVENUECAT_WEBHOOK_AUTH>`

Test by sending a fake event from the dashboard. The function should respond `200 ok:true`.

## 3. New migrations to apply

Apply in this order from the project root:

```
supabase db push                                  # picks up everything under supabase/migrations/
# Or explicitly, if you do manual application:
psql "$DATABASE_URL" -f supabase/migrations/20260525_app_configs_rls.sql
psql "$DATABASE_URL" -f supabase/migrations/20260525_server_free_limits.sql
```

After applying, confirm RLS on `app_configs`:

```sql
select relname, relrowsecurity, relforcerowsecurity
from pg_class
where relname = 'app_configs';
-- relrowsecurity should be true
```

## 4. Server-side free-tier enforcement — opt-in flip

The triggers from `20260525_server_free_limits.sql` are deployed in NO-OP mode. Before flipping them on:

1. Audit users currently over the soft limits (these would be blocked from creating new rows):

```sql
with limits as (
  select
    (config_value->>'tasks_free_limit')::int as tasks_limit,
    (config_value->>'habits_free_limit')::int as habits_limit,
    (config_value->>'notes_free_limit')::int as notes_limit
  from public.app_configs where config_key = 'premium'
)
select 'pareto_tasks' as tbl, created_by, count(*) as n from public.pareto_tasks
  group by created_by
  having count(*) >= (select tasks_limit from limits)
union all
select 'habits', created_by, count(*) from public.habits
  group by created_by
  having count(*) >= (select habits_limit from limits)
union all
select 'notes', created_by, count(*) from public.notes
  group by created_by
  having count(*) >= (select notes_limit from limits);
```

2. Cross-check those `created_by` against premium status (`_wakeapp_is_premium(uid)`); non-premium users above the limit need either grandfathering or a notification.

3. When ready, enable:

```sql
update public.app_configs
set config_value = coalesce(config_value, '{}'::jsonb)
  || jsonb_build_object('server_free_limits_enforced', true)
where config_key = 'premium';
```

To disable, set it back to `false`.

## 5. Supabase Dashboard — rate limits (M-2)

Dashboard → Functions → (each function) → Settings → Rate Limit:

- `revenuecat-webhook`: 600/min per IP (RevenueCat retries fast).
- `grant-beta-premium`: 5/min per IP, 30/hour per user.
- `delete-account`: 5/min per IP, 3/hour per user.

## 6. Supabase Auth — confirm email required

Dashboard → Authentication → Sign In / Up:

- Enable **Confirm email**.
- Disable any sign-up flow that bypasses email confirmation (passwordless OTP is fine; magic links by definition confirm the email).

This makes the new `email_confirmed_at` check in `grant-beta-premium` enforceable.

## 7. App Store Connect — export compliance (M-4)

In App Store Connect → My Apps → WakeApp → App Information → App Privacy → Export Compliance:

- Declare: **My app uses standard encryption.**
- Submit the compliance documentation. This matches `ITSAppUsesNonExemptEncryption=false` in `Info.plist`.

## 8. Build pipeline — required `--dart-define`

CI/CD must build with:

```
flutter build ios --release \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key> \
  --dart-define=GOOGLE_WEB_CLIENT_ID=<id> \
  --dart-define=GOOGLE_IOS_CLIENT_ID=<id>
```

Without these defines the binary will boot but log `[SupabaseConfig] No --dart-define provided` (debug mode only). Production builds MUST pass them.

## 9. Storage buckets used by the app

`supabase/functions/delete-account/index.ts` removes user-owned objects from these buckets at account deletion time:

- `avatars`

If you add new buckets that contain per-user objects under `<userId>/...`, update `userStorageBuckets` in that file.

## 10. Periodic verification queries

Run these monthly to catch drift:

```sql
-- Any public.* table without RLS (excluding views and partitioned children):
select table_schema || '.' || table_name as relation
from information_schema.tables t
where t.table_schema = 'public'
  and t.table_type = 'BASE TABLE'
  and not exists (
    select 1 from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = t.table_name
      and c.relrowsecurity = true
  );

-- Webhook events with null created_by (anonymized post-delete):
select count(*) from public.billing_webhook_events where created_by is null;

-- Subscriptions that never received an event in the last 90 days:
select created_by, status, last_synced_at from public.billing_subscriptions
where last_synced_at < now() - interval '90 days';
```
