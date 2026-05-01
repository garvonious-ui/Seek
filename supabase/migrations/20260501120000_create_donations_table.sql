-- Records of completed Stripe donations from the Support Seek flow.
-- Inserted by the stripe-webhook Edge Function on checkout.session.completed.
-- Operator reads donor data via Supabase dashboard (service_role).
create table public.donations (
  id uuid primary key default gen_random_uuid(),
  stripe_session_id text unique not null,
  stripe_payment_intent_id text,
  amount_cents integer not null,
  currency text not null default 'usd',
  donor_email text,
  donor_name text,
  status text not null default 'completed',
  created_at timestamptz not null default now()
);

create index donations_created_at_idx on public.donations (created_at desc);

alter table public.donations enable row level security;

-- No public-facing policies. RLS enabled with no policies = anon and
-- authenticated roles get zero access. Webhook Edge Function uses the
-- service_role key, which bypasses RLS automatically.

comment on table public.donations is
  'Records of completed Stripe donations from the Support Seek flow.';
comment on column public.donations.amount_cents is
  'Stripe sends amounts in the smallest currency unit. Divide by 100 for USD display.';
comment on column public.donations.status is
  'completed | refunded. Updated by the webhook on charge.refunded events.';
