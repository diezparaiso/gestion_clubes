-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): trazabilidad de pagos y recibos de participaciones.
alter table public.raffle_tickets
  add column if not exists profile_id uuid references public.profiles(id) on delete set null,
  add column if not exists payment_reference text,
  add column if not exists paid_at timestamptz,
  add column if not exists receipt_number text,
  add column if not exists receipt_email_sent_at timestamptz;

create unique index if not exists raffle_tickets_receipt_number_unique
  on public.raffle_tickets (receipt_number)
  where receipt_number is not null;

create index if not exists raffle_tickets_profile_idx
  on public.raffle_tickets (profile_id);

alter table public.raffle_tickets enable row level security;

drop policy if exists raffle_tickets_receipt_owner_select on public.raffle_tickets;
create policy raffle_tickets_receipt_owner_select
on public.raffle_tickets
for select
to authenticated
using (
  profile_id = auth.uid()
  or exists (
    select 1
    from public.raffles r
    where r.id = raffle_id
      and public.has_club_permission(r.club_id, 'raffles_view')
  )
);

create or replace function public.record_raffle_payment(
  target_ticket_id uuid,
  target_profile_id uuid,
  target_payment_reference text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  t public.raffle_tickets%rowtype;
  r public.raffles%rowtype;
  receipt text;
begin
  if auth.role() <> 'service_role' then
    raise exception 'Esta operación solo puede ejecutarse desde el backend de pagos';
  end if;

  select * into t
  from public.raffle_tickets
  where id = target_ticket_id
  for update;

  if t.id is null then
    raise exception 'Participación no encontrada';
  end if;

  select * into r
  from public.raffles
  where id = t.raffle_id;

  if r.id is null then
    raise exception 'Rifa no encontrada';
  end if;

  receipt := 'RIFA-' || upper(substr(replace(t.id::text, '-', ''), 1, 12));

  update public.raffle_tickets
  set profile_id = target_profile_id,
      payment_reference = nullif(trim(target_payment_reference), ''),
      payment_status = 'paid',
      paid_at = coalesce(paid_at, now()),
      receipt_number = coalesce(receipt_number, receipt)
  where id = t.id;

  return jsonb_build_object(
    'ticket_id', t.id,
    'raffle_id', t.raffle_id,
    'number', t.number,
    'payment_reference', target_payment_reference,
    'receipt_number', receipt
  );
end;
$$;

revoke all on function public.record_raffle_payment(uuid, uuid, text) from public;
revoke all on function public.record_raffle_payment(uuid, uuid, text) from anon;
revoke all on function public.record_raffle_payment(uuid, uuid, text) from authenticated;
grant execute on function public.record_raffle_payment(uuid, uuid, text) to service_role;
