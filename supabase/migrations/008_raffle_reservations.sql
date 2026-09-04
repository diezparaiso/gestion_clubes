alter table public.raffle_tickets
  add column reservation_expires_at timestamptz;

create index raffle_tickets_reservation_expiry_idx
  on public.raffle_tickets (raffle_id, reservation_expires_at)
  where payment_status = 'pending';

create or replace function public.get_public_raffle_numbers(target_club_slug text, target_raffle_slug text)
returns table (number integer)
language sql
security definer
set search_path = public
as $$
  select t.number
  from public.raffle_tickets t
  join public.raffles r on r.id = t.raffle_id
  join public.clubs c on c.id = r.club_id
  where c.slug::text = lower(target_club_slug)
    and r.slug::text = lower(target_raffle_slug)
    and r.status = 'active'
    and (t.payment_status = 'paid' or (t.payment_status = 'pending' and t.reservation_expires_at > timezone('utc', now())))
  order by t.number;
$$;

create or replace function public.reserve_public_raffle_numbers(
  target_club_slug text,
  target_raffle_slug text,
  selected_numbers integer[],
  target_buyer_name text,
  target_buyer_email text,
  target_buyer_phone text default null
)
returns integer[]
language plpgsql
security definer
set search_path = public
as $$
declare
  target_raffle public.raffles;
  selected_number integer;
begin
  if coalesce(array_length(selected_numbers, 1), 0) < 1 or array_length(selected_numbers, 1) > 10 then
    raise exception 'Selecciona entre 1 y 10 números';
  end if;
  if trim(coalesce(target_buyer_name, '')) = '' or position('@' in target_buyer_email) < 2 then
    raise exception 'Los datos del comprador no son válidos';
  end if;

  select r.* into target_raffle
  from public.raffles r
  join public.clubs c on c.id = r.club_id
  where c.slug::text = lower(target_club_slug)
    and r.slug::text = lower(target_raffle_slug)
    and r.status = 'active'
    and r.end_at > timezone('utc', now());
  if not found then raise exception 'La rifa no está disponible'; end if;

  delete from public.raffle_tickets
  where raffle_id = target_raffle.id
    and payment_status = 'pending'
    and reservation_expires_at <= timezone('utc', now());

  foreach selected_number in array selected_numbers loop
    if selected_number < 0 or selected_number >= target_raffle.total_numbers then
      raise exception 'Número de rifa no válido';
    end if;
    if exists (
      select 1 from public.raffle_tickets t
      where t.raffle_id = target_raffle.id
        and t.number = selected_number
        and (t.payment_status = 'paid' or (t.payment_status = 'pending' and t.reservation_expires_at > timezone('utc', now())))
    ) then
      raise exception 'Uno de los números seleccionados ya no está disponible';
    end if;
    insert into public.raffle_tickets (club_id, raffle_id, number, buyer_name, buyer_email, buyer_phone, payment_status, reservation_expires_at)
    values (target_raffle.club_id, target_raffle.id, selected_number, trim(target_buyer_name), lower(trim(target_buyer_email)), nullif(trim(target_buyer_phone), ''), 'pending', timezone('utc', now()) + interval '15 minutes');
  end loop;
  return selected_numbers;
end;
$$;

revoke all on function public.get_public_raffle_numbers(text, text) from public;
grant execute on function public.get_public_raffle_numbers(text, text) to anon, authenticated;
revoke all on function public.reserve_public_raffle_numbers(text, text, integer[], text, text, text) from public;
grant execute on function public.reserve_public_raffle_numbers(text, text, integer[], text, text, text) to anon, authenticated;