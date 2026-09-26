-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): rifa mensual, renovaciones e histórico.
alter table public.raffles
  add column if not exists monthly_day integer,
  add column if not exists subscription_enabled boolean not null default false;

alter table public.raffles
  drop constraint if exists raffles_monthly_day_check;
alter table public.raffles
  add constraint raffles_monthly_day_check
  check (monthly_day is null or (monthly_day between 1 and 28));

alter table public.raffles
  drop constraint if exists raffles_monthly_type_check;
alter table public.raffles
  add constraint raffles_monthly_type_check
  check (
    (raffle_type = 'mensual' and monthly_day is not null)
    or raffle_type <> 'mensual'
  );

create table if not exists public.raffle_monthly_subscriptions (
  id uuid primary key default gen_random_uuid(),
  raffle_id uuid not null references public.raffles(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  number integer not null,
  amount numeric(10,2) not null,
  currency text not null default 'eur',
  status text not null default 'active' check (status in ('active','paused','cancelled','past_due')),
  provider_customer_id text,
  provider_subscription_id text,
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (raffle_id, profile_id),
  unique (raffle_id, number)
);

create table if not exists public.raffle_monthly_results (
  id uuid primary key default gen_random_uuid(),
  raffle_id uuid not null references public.raffles(id) on delete cascade,
  draw_month date not null,
  winning_number integer not null,
  winner_profile_id uuid references public.profiles(id) on delete set null,
  prize_amount numeric(12,2) not null default 0,
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (raffle_id, draw_month),
  unique (raffle_id, draw_month, winning_number)
);

create index if not exists raffle_monthly_results_raffle_month_idx
  on public.raffle_monthly_results (raffle_id, draw_month desc);

alter table public.raffle_monthly_subscriptions enable row level security;
alter table public.raffle_monthly_results enable row level security;

create policy raffle_monthly_subscriptions_select on public.raffle_monthly_subscriptions
for select to authenticated using (
  profile_id = auth.uid()
  or exists (
    select 1 from public.raffles r
    where r.id = raffle_id and public.has_club_permission(r.club_id, 'raffles_view')
  )
);

create policy raffle_monthly_results_select on public.raffle_monthly_results
for select to authenticated using (
  exists (
    select 1 from public.raffles r
    where r.id = raffle_id and public.has_club_permission(r.club_id, 'raffles_view')
  )
);

create or replace function public.register_monthly_result(
  target_raffle_id uuid,
  target_month date,
  target_winning_number integer,
  target_prize_amount numeric,
  target_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.raffles%rowtype;
  winner uuid;
  result_id uuid;
  notification_id uuid;
begin
  select * into r from public.raffles where id = target_raffle_id for update;
  if r.id is null then raise exception 'Rifa no encontrada'; end if;
  if r.raffle_type <> 'mensual' then raise exception 'Esta operación solo está disponible para rifas mensuales'; end if;
  if not public.has_club_permission(r.club_id, 'raffles_manage') then raise exception 'No tienes permiso para gestionar rifas'; end if;
  if target_winning_number < 1 or target_winning_number > r.total_numbers then raise exception 'Número ganador fuera de rango'; end if;
  if target_prize_amount < 0 then raise exception 'El importe del premio no puede ser negativo'; end if;

  select profile_id into winner
  from public.raffle_monthly_subscriptions
  where raffle_id = r.id and number = target_winning_number and status = 'active'
  limit 1;

  if winner is null then raise exception 'El número ganador no tiene una suscripción mensual activa'; end if;

  insert into public.raffle_monthly_results
    (raffle_id, draw_month, winning_number, winner_profile_id, prize_amount, notes, created_by)
  values
    (r.id, target_month, target_winning_number, winner, target_prize_amount, target_notes, auth.uid())
  returning id into result_id;

  insert into public.notifications (club_id, title, body, type, target)
  values (r.club_id, 'Resultado de la rifa mensual',
          'El número ' || target_winning_number || ' ha sido premiado este mes en ' || r.title || '.',
          'raffle_monthly_result', 'profile')
  returning id into notification_id;

  insert into public.notification_deliveries (notification_id, profile_id)
  values (notification_id, winner);

  return jsonb_build_object('id', result_id, 'winning_number', target_winning_number, 'winner_profile_id', winner);
end;
$$;

revoke all on function public.register_monthly_result(uuid, date, integer, numeric, text) from public;
grant execute on function public.register_monthly_result(uuid, date, integer, numeric, text) to authenticated;
