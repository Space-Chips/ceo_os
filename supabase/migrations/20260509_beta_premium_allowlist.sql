create table if not exists public.beta_premium_allowlist (
  email text primary key,
  note text,
  created_at timestamptz not null default now()
);

alter table public.beta_premium_allowlist enable row level security;

-- No policies: this table is only accessed by service-role via Edge Functions.
