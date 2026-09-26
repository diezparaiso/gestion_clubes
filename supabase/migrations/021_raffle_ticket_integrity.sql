-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Valida que cada número de rifa esté dentro del rango configurado.
create or replace function public.validate_raffle_ticket_number()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  max_number integer;
begin
  select total_numbers into max_number from public.raffles where id = new.raffle_id;
  if max_number is null then raise exception 'La rifa no existe'; end if;
  if new.number < 1 or new.number > max_number then
    raise exception 'El número % está fuera del rango 1-%', new.number, max_number;
  end if;
  if new.club_id <> (select club_id from public.raffles where id = new.raffle_id) then
    raise exception 'La participación no pertenece al club de la rifa';
  end if;
  return new;
end;
$$;

drop trigger if exists raffle_ticket_validate_number on public.raffle_tickets;
create trigger raffle_ticket_validate_number
before insert or update of raffle_id, number, club_id on public.raffle_tickets
for each row execute function public.validate_raffle_ticket_number();
