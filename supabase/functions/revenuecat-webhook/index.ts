import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type Json = string | number | boolean | null | { [key: string]: Json } | Json[];

type RevenueCatEvent = {
  id?: string;
  type?: string;
  app_user_id?: string;
  original_app_user_id?: string;
  product_id?: string;
  entitlement_ids?: string[];
  store?: string;
  purchased_at_ms?: number;
  expiration_at_ms?: number | null;
  canceled_at_ms?: number | null;
  event_timestamp_ms?: number;
  period_type?: string;
  aliases?: string[];
  [key: string]: Json | undefined;
};

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const revenueCatAuth = Deno.env.get('REVENUECAT_WEBHOOK_AUTH') ?? '';

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error('Supabase service role environment is missing.');
}

// Fail loud at boot if the shared secret is missing — this webhook MUST be
// authenticated. RevenueCat sends this header per dashboard configuration.
if (!revenueCatAuth) {
  throw new Error('REVENUECAT_WEBHOOK_AUTH is not configured.');
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false },
});

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const header = request.headers.get('authorization') ?? '';
  const expected = `Bearer ${revenueCatAuth}`;
  if (header !== expected) {
    return new Response('Unauthorized', { status: 401 });
  }

  let payload: Record<string, Json>;
  try {
    payload = await request.json();
  } catch (_) {
    return new Response('Invalid JSON', { status: 400 });
  }

  const event = ((payload['event'] as Record<string, Json> | undefined) ??
    payload) as unknown as RevenueCatEvent;
  const appUserId =
    normalizeText(event.app_user_id) ??
    normalizeText(event.original_app_user_id);
  if (!appUserId) {
    return new Response('Missing app_user_id', { status: 400 });
  }
  if (!UUID_PATTERN.test(appUserId)) {
    return new Response('Invalid app_user_id', { status: 400 });
  }

  // Confirm the user exists in auth.users before treating app_user_id as a
  // billable identity. Prevents a leaked bearer from granting premium to
  // arbitrary UUIDs that don't match a real account.
  const { data: userLookup, error: userLookupError } =
    await supabase.auth.admin.getUserById(appUserId);
  if (userLookupError || !userLookup?.user) {
    return new Response('Unknown app_user_id', { status: 404 });
  }

  // Require a stable provider event id for idempotency. Without it we cannot
  // safely dedupe replays and out-of-order deliveries.
  const eventId = normalizeText(event.id);
  if (!eventId) {
    return new Response('Missing event.id', { status: 400 });
  }

  const status = deriveStatus(event);
  const providerPayload = payload as Json;
  const periodStartsAt = toIsoString(event.purchased_at_ms);
  const periodEndsAt = toIsoString(event.expiration_at_ms);
  const canceledAt = toIsoString(event.canceled_at_ms);

  const { error: eventError } = await supabase.from('billing_webhook_events').upsert(
    {
      provider: 'revenuecat',
      event_id: eventId,
      event_type: normalizeText(event.type),
      created_by: appUserId,
      payload: providerPayload,
    },
    { onConflict: 'provider,event_id' },
  );

  if (eventError) {
    await supabase.from('billing_subscriptions').upsert(
      {
        created_by: appUserId,
        provider: 'revenuecat',
        status: 'inactive',
        last_error: `Failed to persist webhook event: ${eventError.message}`,
        last_error_at: new Date().toISOString(),
        last_webhook_event_id: eventId,
        last_webhook_event_at: new Date().toISOString(),
        last_synced_at: new Date().toISOString(),
      },
      { onConflict: 'created_by' },
    );
    return new Response(`Failed to persist webhook event: ${eventError.message}`, {
      status: 500,
    });
  }

  // Ordering guard: ignore deliveries that are older than what we already
  // persisted for this customer. RevenueCat can retry / reorder events.
  const incomingTimestampMs = Number.isFinite(event.event_timestamp_ms ?? NaN)
    ? (event.event_timestamp_ms as number)
    : Date.now();
  const incomingTimestamp = new Date(incomingTimestampMs);

  const { data: existingSubscription } = await supabase
    .from('billing_subscriptions')
    .select('last_webhook_event_at, last_webhook_event_id')
    .eq('created_by', appUserId)
    .maybeSingle();

  if (
    existingSubscription?.last_webhook_event_id === eventId
  ) {
    // Exact replay of the same event — already mirrored.
    return Response.json({ ok: true, deduped: true });
  }
  if (
    existingSubscription?.last_webhook_event_at &&
    new Date(existingSubscription.last_webhook_event_at).getTime() >
      incomingTimestamp.getTime()
  ) {
    // Stale (out-of-order) event — keep the webhook event log row but skip
    // overwriting the subscription state.
    return Response.json({ ok: true, skipped: 'stale' });
  }

  const { error: subscriptionError } = await supabase.from(
    'billing_subscriptions',
  ).upsert(
    {
      created_by: appUserId,
      status,
      provider: 'revenuecat',
      external_customer_id: normalizeText(event.original_app_user_id) ?? appUserId,
      external_subscription_id: normalizeText(event.id) ?? normalizeText(event.product_id),
      product_id: normalizeText(event.product_id),
      price_id: normalizeText(event.product_id),
      trial_ends_at:
        event.period_type === 'trial' ? periodEndsAt : null,
      period_starts_at: periodStartsAt,
      period_ends_at: periodEndsAt,
      canceled_at: canceledAt,
      provider_payload: providerPayload,
      last_webhook_event_id: eventId,
      last_webhook_event_at: incomingTimestamp.toISOString(),
      last_error: null,
      last_error_at: null,
      last_synced_at: new Date().toISOString(),
    },
    { onConflict: 'created_by' },
  );

  if (subscriptionError) {
    await supabase.from('billing_subscriptions').upsert(
      {
        created_by: appUserId,
        provider: 'revenuecat',
        status: 'inactive',
        last_error: `Failed to upsert billing subscription: ${subscriptionError.message}`,
        last_error_at: new Date().toISOString(),
        last_webhook_event_id: eventId,
        last_webhook_event_at: new Date().toISOString(),
        last_synced_at: new Date().toISOString(),
      },
      { onConflict: 'created_by' },
    );
    return new Response(
      `Failed to upsert billing subscription: ${subscriptionError.message}`,
      { status: 500 },
    );
  }

  return Response.json({ ok: true });
});

function normalizeText(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const normalized = value.trim();
  return normalized.length == 0 ? null : normalized;
}

function toIsoString(timestampMs: number | null | undefined): string | null {
  if (timestampMs == null) return null;
  if (!Number.isFinite(timestampMs)) return null;
  return new Date(timestampMs).toISOString();
}

function deriveStatus(event: RevenueCatEvent): string {
  const type = (event.type ?? '').toUpperCase();
  switch (type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'NON_RENEWING_PURCHASE':
    case 'PRODUCT_CHANGE':
    case 'UNCANCELLATION':
      return event.period_type === 'trial' ? 'trialing' : 'active';
    case 'BILLING_ISSUE':
    case 'SUBSCRIPTION_PAUSED':
      return 'past_due';
    case 'CANCELLATION':
      return 'canceled';
    case 'EXPIRATION':
      return 'inactive';
    default:
      return event.period_type === 'trial' ? 'trialing' : 'active';
  }
}
