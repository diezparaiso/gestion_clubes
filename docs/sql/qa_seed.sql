-- Solo para pruebas QA locales/remotas autorizadas. No ejecutado por Copilot.
-- Inserta como máximo una participación QA marcada como pagada por rifa.
-- No crea ni confirma ningun pago real, ni invoca Stripe o record_raffle_payment.
-- Requiere la rifa qa-ended-raffle-... creada por security_e2e.ps1.

begin;

do $$
declare
  v_raffle record;
  v_number integer;
  v_receipt text;
begin
  select r.id, r.club_id, r.total_numbers
    into v_raffle
  from public.raffles r
  join public.clubs c on c.id = r.club_id
  where c.slug::text like 'qa-club-a-%'
    and r.slug::text like 'qa-ended-raffle-%'
    and r.status = 'active'
    and r.end_at < now()
  order by r.created_at desc
  limit 1;

  if v_raffle.id is null then
    raise exception 'No ended active QA raffle found; no rows inserted';
  end if;

  if exists (
    select 1
    from public.raffle_tickets t
    where t.raffle_id = v_raffle.id
      and t.payment_reference = 'qa-test-only'
  ) then
    return;
  end if;

  select coalesce(max(t.number), 0) + 1
    into v_number
  from public.raffle_tickets t
  where t.raffle_id = v_raffle.id;

  if v_number > v_raffle.total_numbers then
    raise exception 'No unoccupied ticket number is available on the QA raffle';
  end if;

  v_receipt := 'QA-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));

  insert into public.raffle_tickets (
    club_id,
    raffle_id,
    number,
    buyer_name,
    buyer_email,
    payment_status,
    payment_reference,
    paid_at,
    receipt_number,
    purchased_at
  )
  values (
    v_raffle.club_id,
    v_raffle.id,
    v_number,
    'qa-test-buyer-' || to_char(current_date, 'YYYYMMDD'),
    'qa-' || to_char(current_date, 'YYYYMMDD') || '-test-buyer@example.com',
    'paid',
    'qa-test-only',
    now(),
    v_receipt,
    now()
  );
end;
$$;

commit;
