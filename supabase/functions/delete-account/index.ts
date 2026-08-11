import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

if (!supabaseUrl || !serviceRoleKey || !anonKey) {
  throw new Error('Supabase environment is missing required keys.');
}

const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false },
});

// Tables whose rows should be hard-deleted when a user deletes their account.
// NOTE: `billing_webhook_events` is intentionally NOT in this list — we keep
// the financial audit trail and anonymise it instead (see anonymizableTables).
const deletableTables = [
  'habit_completions',
  'habit_logs',
  'habits',
  'calendar_events',
  'pareto_tasks',
  'task_groups',
  'focus_sessions',
  'block_lists',
  'blocked_apps',
  'notes',
  'objectives',
  'screen_time_logs',
  'event_types',
  'leaderboard_entries',
  'friend_connections',
  'weekly_habit_scores',
  'weekly_contracts',
  'user_ranks',
  'win_streaks',
  'user_entitlements',
  'billing_subscriptions',
  'app_settings',
  'family_groups',
  'family_group_members',
  'family_sessions',
  'advanced_weekly_stats',
  'advanced_monthly_stats',
  'advanced_biannual_reports',
  'advanced_stat_snapshots',
];

// Tables we keep for compliance/audit purposes but where the link to the
// deleted user must be severed.
const anonymizableTables = [
  'billing_webhook_events',
];

// Storage buckets the app may have uploaded user-owned objects to. Adjust
// this list when adding new buckets.
const userStorageBuckets = [
  'avatars',
];

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const authorization = request.headers.get('authorization');
  if (!authorization) {
    return new Response('Missing authorization header', { status: 401 });
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false },
    global: { headers: { Authorization: authorization } },
  });

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();

  if (userError || !user) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    // 1) Remove user-owned objects from storage. Without this, the
    //    `on delete set null` FK on storage.objects would leave orphan files
    //    behind after the auth.users row is deleted (GDPR breach + bucket
    //    cost). We collect file paths under <userId>/... within each bucket.
    for (const bucket of userStorageBuckets) {
      try {
        const { data: listed, error: listError } = await admin.storage
          .from(bucket)
          .list(user.id, { limit: 1000 });
        if (listError) {
          // Bucket may not exist in some environments — ignore.
          continue;
        }
        if (listed && listed.length > 0) {
          const paths = listed.map((entry) => `${user.id}/${entry.name}`);
          await admin.storage.from(bucket).remove(paths);
        }
      } catch (_) {
        // Best-effort cleanup; do not block account deletion on storage errors.
      }
    }

    // 2) Anonymise audit-tracked rows we are required to keep (billing events).
    for (const table of anonymizableTables) {
      const { error } = await admin
        .from(table)
        .update({ created_by: null })
        .eq('created_by', user.id);
      if (error && !isMissingRelation(error)) {
        throw error;
      }
    }

    // 3) Hard-delete all user-owned application rows.
    for (const table of deletableTables) {
      const { error } = await admin.from(table).delete().eq('created_by', user.id);
      if (error && !isMissingRelation(error)) {
        throw error;
      }
    }

    const { error: profileError } = await admin.from('profiles').delete().eq('id', user.id);
    if (profileError && !isMissingRelation(profileError)) {
      throw profileError;
    }

    // 4) Finally remove the auth user. Doing this last guarantees the data
    //    above is gone before the identity disappears, so a webhook racing
    //    against deletion will fail the FK check on auth.users rather than
    //    silently recreating rows for an already-deleted account.
    const { error: deleteUserError } = await admin.auth.admin.deleteUser(user.id);
    if (deleteUserError) {
      throw deleteUserError;
    }

    return Response.json({ ok: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown deletion error';
    return Response.json({ ok: false, error: message }, { status: 500 });
  }
});

function isMissingRelation(error: { message?: string } | null): boolean {
  const message = error?.message?.toLowerCase() ?? '';
  return message.includes('relation') && message.includes('does not exist');
}
