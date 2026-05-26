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

  // Block unconfirmed accounts: otherwise an attacker can sign up with an
  // allowlisted email they don't own and claim premium without ever
  // proving ownership of the mailbox.
  if (!user.email_confirmed_at) {
    return new Response('Email not confirmed', { status: 403 });
  }

  const email = (user.email ?? '').trim().toLowerCase();
  if (!email) {
    return new Response('Missing email', { status: 400 });
  }

  const { data: allowlisted, error: allowlistError } = await admin
    .from('beta_premium_allowlist')
    .select('email')
    .eq('email', email)
    .maybeSingle();

  if (allowlistError) {
    return Response.json(
      { ok: false, error: allowlistError.message },
      { status: 500 },
    );
  }

  if (!allowlisted) {
    return new Response('Not allowlisted', { status: 403 });
  }

  const { error } = await admin.from('user_entitlements').upsert(
    {
      created_by: user.id,
      premium_override: true,
      premium_override_reason: 'beta_allowlist',
      premium_override_expires_at: null,
    },
    { onConflict: 'created_by' },
  );

  if (error) {
    return Response.json({ ok: false, error: error.message }, { status: 500 });
  }

  return Response.json({ ok: true });
});
