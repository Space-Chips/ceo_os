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
  'billing_webhook_events',
  'family_groups',
  'family_group_members',
  'family_sessions',
  'advanced_weekly_stats',
  'advanced_monthly_stats',
  'advanced_biannual_reports',
  'advanced_stat_snapshots',
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
