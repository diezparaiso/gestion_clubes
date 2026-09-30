-- 043_platform_commissions.sql
-- Modelo de ingresos de la plataforma: comisión del 5 % por venta confirmada.
-- No reutiliza financial_transactions: esa tabla pertenece a la tesorería de cada club.
-- Las ventas se registran desde backend confiable (pasarela/webhook con service_role).

create table public.platform_settings (
  setting_key text primary key,
  setting_value jsonb not null,
  updated_at timestamptz not null default timezone('utc', now()),
  updated_by uuid references auth.users(id)
);

insert into public.platform_settings (setting_key, setting_value)
values ('commission_rate', '{"rate": 0.05, "currency": "EUR"}'::jsonb)
on conflict (setting_key) do nothing;

create table public.platform_sales (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete restrict,
  source text not null check (source ~ '^[a-z][a-z0-9_]{1,40}$'),
  source_sale_id text not null,
  gross_amount numeric(12,2) not null check (gross_amount > 0),
  currency char(3) not null default 'EUR' check (currency = upper(currency)),
  status text not null default 'paid' check (status in ('paid', 'refunded', 'partially_refunded')),
  commission_rate numeric(7,6) not null default 0.05 check (commission_rate >= 0 and commission_rate <= 1),
  commission_amount numeric(12,2) generated always as
    (round(gross_amount * commission_rate, 2)) stored,
  refunded_amount numeric(12,2) not null default 0 check (refunded_amount >= 0 and refunded_amount <= gross_amount),
  payment_provider text,
  provider_payment_id text,
  paid_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  metadata jsonb not null default '{}'::jsonb,
  unique (source, source_sale_id),
  check (jsonb_typeof(metadata) = 'object')
);

create index platform_sales_club_paid_at_idx on public.platform_sales (club_id, paid_at desc);
create index platform_sales_paid_at_idx on public.platform_sales (paid_at desc);
alter table public.platform_settings enable row level security;
alter table public.platform_sales enable row level security;

-- No se concede acceso directo a la tabla de ventas ni a la configuración a usuarios de la app.
revoke all on public.platform_settings from anon, authenticated;
revoke all on public.platform_sales from anon, authenticated;
grant select, insert, update on public.platform_settings to service_role;
grant select, insert, update on public.platform_sales to service_role;

-- Esta función solo puede ser llamada por backend confiable. Captura la tasa vigente
-- en el momento de la venta para que cambios futuros no alteren comisiones históricas.
create or replace function public.record_platform_sale(
  target_club_id uuid,
  target_source text,
  target_source_sale_id text,
  target_gross_amount numeric,
  target_currency text default 'EUR',
  target_payment_provider text default null,
  target_provider_payment_id text default null,
  target_paid_at timestamptz default now(),
  target_metadata jsonb default '{}'::jsonb
)
returns public.platform_sales
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_rate numeric(7,6);
  result_sale public.platform_sales;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'Only trusted payment backend can record platform sales'
      using errcode = '42501';
  end if;
  if target_gross_amount is null or target_gross_amount <= 0 then
    raise exception 'Sale amount must be greater than zero';
  end if;
  if target_currency is null or upper(target_currency) <> 'EUR' then
    raise exception 'Only EUR sales are supported by this commission ledger';
  end if;
  if jsonb_typeof(coalesce(target_metadata, '{}'::jsonb)) <> 'object' then
    raise exception 'metadata must be a JSON object';
  end if;
  if not exists (select 1 from public.clubs c where c.id = target_club_id) then
    raise exception 'Club does not exist';
  end if;

  select (setting_value ->> 'rate')::numeric
    into current_rate
    from public.platform_settings
    where setting_key = 'commission_rate';
  current_rate := coalesce(current_rate, 0.05);

  insert into public.platform_sales (
    club_id, source, source_sale_id, gross_amount, currency, commission_rate,
    payment_provider, provider_payment_id, paid_at, metadata
  ) values (
    target_club_id, lower(target_source), target_source_sale_id,
    target_gross_amount, upper(target_currency), current_rate,
    target_payment_provider, target_provider_payment_id, target_paid_at,
    coalesce(target_metadata, '{}'::jsonb)
  )
  on conflict (source, source_sale_id) do update
    set source_sale_id = excluded.source_sale_id
  returning * into result_sale;

  return result_sale;
end;
$$;

revoke all on function public.record_platform_sale(uuid,text,text,numeric,text,text,text,timestamptz,jsonb) from public, anon, authenticated;
grant execute on function public.record_platform_sale(uuid,text,text,numeric,text,text,text,timestamptz,jsonb) to service_role;

-- Resumen agregado y detalle por club solo para el propietario autenticado.
create or replace function public.get_platform_admin_report(
  from_date timestamptz default null,
  to_date timestamptz default null
)
returns table (
  club_id uuid,
  club_name text,
  club_slug text,
  club_status public.club_status,
  clubs_created_at timestamptz,
  sales_count bigint,
  gross_sales numeric,
  refunded_sales numeric,
  commission_generated numeric,
  commission_net numeric,
  commission_rate numeric
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'Platform administrator access required' using errcode = '42501';
  end if;
  if from_date is not null and to_date is not null and from_date > to_date then
    raise exception 'from_date must be before to_date';
  end if;

  return query
  select c.id, c.public_name, c.slug::text, c.status, c.created_at,
    count(s.id),
    coalesce(sum(s.gross_amount), 0)::numeric,
    coalesce(sum(s.refunded_amount), 0)::numeric,
    coalesce(sum(s.commission_amount), 0)::numeric,
    coalesce(sum(round((s.gross_amount - s.refunded_amount) * s.commission_rate, 2)), 0)::numeric,
    coalesce(max(s.commission_rate), 0.05)::numeric
  from public.clubs c
  left join public.platform_sales s on s.club_id = c.id
    and (from_date is null or s.paid_at >= from_date)
    and (to_date is null or s.paid_at < to_date)
  group by c.id, c.public_name, c.slug, c.status, c.created_at
  order by c.created_at desc;
end;
$$;

revoke all on function public.get_platform_admin_report(timestamptz,timestamptz) from public, anon;
grant execute on function public.get_platform_admin_report(timestamptz,timestamptz) to authenticated;

comment on table public.platform_sales is
  'Registro de ventas confirmadas y comisión de plataforma; escrituras solo desde backend de pagos confiable.';
comment on column public.platform_sales.commission_rate is
  'Tasa congelada al confirmar la venta; valor inicial 0.05 (5 %).';
comment on function public.get_platform_admin_report(timestamptz,timestamptz) is
  'Reporte global por club, solo accesible a usuarios con app_metadata.platform_admin=true.';
