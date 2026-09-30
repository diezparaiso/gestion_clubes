alter table public.clubs add column if not exists stripe_account_id text unique;
alter table public.clubs add column if not exists stripe_onboarding_complete boolean not null default false;
create table if not exists public.club_payouts (
 id uuid primary key default gen_random_uuid(), club_id uuid not null references public.clubs(id) on delete restrict,
 source text not null, source_sale_id text not null, stripe_transfer_id text unique,
 gross_amount numeric(12,2) not null check(gross_amount>0), platform_commission numeric(12,2) not null check(platform_commission>=0),
 stripe_fee_amount numeric(12,2) not null default 0 check(stripe_fee_amount>=0),
 payout_amount numeric(12,2) generated always as (gross_amount-platform_commission) stored,
 currency char(3) not null default 'EUR' check(currency='EUR'),
 status text not null default 'pending' check(status in ('pending','processing','paid','failed','reversed')),
 created_at timestamptz not null default now(), paid_at timestamptz, metadata jsonb not null default '{}'::jsonb,
 unique(source,source_sale_id), check(platform_commission<=gross_amount)
);
alter table public.club_payouts enable row level security;
revoke all on public.club_payouts from anon,authenticated;
grant select,insert,update on public.club_payouts to service_role;
comment on table public.club_payouts is 'Saldo liquidable al club: bruto menos comisión de plataforma del 5 %.';
comment on column public.club_payouts.stripe_fee_amount is 'Comisión de Stripe informativa; este modelo la soporta la plataforma.';
