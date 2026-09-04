create or replace function public.draw_raffle_random(target_raffle_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_raffle public.raffles;
  winning_ticket public.raffle_tickets;
  created_draw public.raffle_draws;
begin
  select r.* into target_raffle
  from public.raffles r
  where r.id = target_raffle_id;

  if not found then raise exception 'La rifa no existe'; end if;
  if not public.is_club_manager(target_raffle.club_id) then raise exception 'No tienes permisos para sortear esta rifa'; end if;
  if target_raffle.status not in ('active', 'closed') then raise exception 'La rifa no está preparada para el sorteo'; end if;
  if exists (select 1 from public.raffle_draws where raffle_id = target_raffle.id) then raise exception 'La rifa ya tiene un sorteo registrado'; end if;

  select t.* into winning_ticket
  from public.raffle_tickets t
  where t.raffle_id = target_raffle.id
    and t.payment_status = 'paid'
  order by random()
  limit 1;

  if not found then raise exception 'No hay participaciones confirmadas'; end if;

  insert into public.raffle_draws (club_id, raffle_id, method, winning_number, winning_ticket_id, executed_by, result_snapshot)
  values (
    target_raffle.club_id,
    target_raffle.id,
    'random_number',
    winning_ticket.number,
    winning_ticket.id,
    auth.uid(),
    jsonb_build_object('selection', 'random_paid_ticket', 'winning_number', winning_ticket.number)
  )
  returning * into created_draw;

  update public.raffles
  set status = 'drawn'
  where id = target_raffle.id;

  return jsonb_build_object(
    'id', created_draw.id,
    'winning_number', created_draw.winning_number,
    'drawn_at', created_draw.drawn_at,
    'method', created_draw.method
  );
end;
$$;

revoke all on function public.draw_raffle_random(uuid) from public;
grant execute on function public.draw_raffle_random(uuid) to authenticated;
