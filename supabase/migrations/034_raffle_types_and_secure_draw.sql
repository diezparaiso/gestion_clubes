-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): modalidades Cesta y Sorteo puro.
alter table public.raffles
  add column if not exists raffle_type text not null default 'sorteoPuro'
    check (raffle_type in ('cesta', 'sorteoPuro', 'mensual')),
  add column if not exists winning_number integer;

alter table public.raffles
  drop constraint if exists raffles_winning_number_check;

alter table public.raffles
  add constraint raffles_winning_number_check
  check (winning_number is null or (winning_number >= 1 and winning_number <= total_numbers));

alter table public.notifications
  drop constraint if exists notifications_type_check;
alter table public.notifications
  add constraint notifications_type_check
  check (type in ('news', 'event', 'raffle', 'system', 'other', 'raffle_winner', 'raffle_monthly_result'));

alter table public.notifications
  drop constraint if exists notifications_target_check;
alter table public.notifications
  add constraint notifications_target_check
  check (target in ('all_members', 'managers', 'members', 'staff', 'profile'));

create unique index if not exists raffle_tickets_raffle_number_unique
  on public.raffle_tickets (raffle_id, number);

create or replace function public.set_raffle_manual_winner(
  target_raffle_id uuid,
  target_winning_number integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.raffles%rowtype;
  t public.raffle_tickets%rowtype;
  winner_profile_id uuid;
  notification_id uuid;
  result jsonb;
begin
  select * into r from public.raffles where id = target_raffle_id for update;
  if r.id is null then raise exception 'Rifa no encontrada'; end if;
  if not public.has_club_permission(r.club_id, 'raffles_manage') then raise exception 'No tienes permiso para gestionar rifas'; end if;
  if r.raffle_type <> 'cesta' then raise exception 'Esta operación solo está disponible para rifas tipo Cesta'; end if;
  if now() < r.end_at then raise exception 'La rifa todavía no ha terminado'; end if;
  if target_winning_number < 1 or target_winning_number > r.total_numbers then raise exception 'Número ganador fuera de rango'; end if;

  select * into t from public.raffle_tickets
  where raffle_id = r.id and number = target_winning_number and payment_status = 'paid'
  limit 1;
  if t.id is null then raise exception 'El número ganador debe estar entre las participaciones confirmadas'; end if;

  update public.raffles
  set winning_number = target_winning_number, status = 'drawn'
  where id = r.id;

  select id into winner_profile_id from public.profiles where lower(email) = lower(t.buyer_email) limit 1;
  if winner_profile_id is not null then
    insert into public.notifications (club_id, title, body, type, target)
    values (r.club_id, '¡Has ganado la rifa!', 'El número ' || target_winning_number || ' ha resultado agraciado en ' || r.title || '.', 'raffle_winner', 'profile')
    returning id into notification_id;
    insert into public.notification_deliveries (notification_id, profile_id)
    values (notification_id, winner_profile_id);
  end if;

    insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
    values (r.club_id, auth.uid(), 'raffle_draw', 'raffle', r.id,
      jsonb_build_object('draw_method', 'manual', 'winning_number', target_winning_number, 'raffle_type', r.raffle_type));

  return jsonb_build_object(
    'id', gen_random_uuid(),
    'raffle_id', r.id,
    'winning_number', target_winning_number,
    'drawn_at', now(),
    'method', 'president_selected'
  );
end;
$$;

create or replace function public.draw_raffle_random_secure(target_raffle_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.raffles%rowtype;
  chosen_number integer;
  count_numbers integer;
  raw_value bigint;
  limit_value bigint;
  ticket_exists boolean;
begin
  select * into r from public.raffles where id = target_raffle_id for update;
  if r.id is null then raise exception 'Rifa no encontrada'; end if;
  if not public.has_club_permission(r.club_id, 'raffles_manage') then raise exception 'No tienes permiso para gestionar rifas'; end if;
  if r.raffle_type <> 'sorteoPuro' then raise exception 'Esta rifa requiere selección manual del ganador'; end if;
  if r.winning_number is not null or r.status = 'drawn' then raise exception 'La rifa ya ha sido sorteada'; end if;

  select count(*) into count_numbers
  from public.raffle_tickets
  where raffle_id = r.id and payment_status = 'paid';
  if count_numbers = 0 then raise exception 'No hay participaciones confirmadas'; end if;

  -- Selección criptográficamente aleatoria y sin sesgo por módulo.
  loop
    raw_value := ('x' || encode(gen_random_bytes(8), 'hex'))::bit(64)::bigint;
    raw_value := raw_value & 9223372036854775807;
    limit_value := 9223372036854775807 - mod(9223372036854775807, count_numbers);
    exit when raw_value < limit_value;
  end loop;

  select number into chosen_number
  from (
    select number, row_number() over (order by number) - 1 as idx
    from public.raffle_tickets
    where raffle_id = r.id and payment_status = 'paid'
  ) q
  where idx = mod(raw_value, count_numbers);

  update public.raffles set winning_number = chosen_number, status = 'drawn' where id = r.id;

    insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
    values (r.club_id, auth.uid(), 'raffle_draw', 'raffle', r.id,
      jsonb_build_object('draw_method', 'cryptographic_random', 'winning_number', chosen_number, 'raffle_type', r.raffle_type, 'random_source', 'pgcrypto'));

  return jsonb_build_object(
    'id', gen_random_uuid(),
    'raffle_id', r.id,
    'winning_number', chosen_number,
    'drawn_at', now(),
    'method', 'cryptographic_random'
  );
end;
$$;

revoke all on function public.set_raffle_manual_winner(uuid, integer) from public;
grant execute on function public.set_raffle_manual_winner(uuid, integer) to authenticated;
revoke all on function public.draw_raffle_random_secure(uuid) from public;
grant execute on function public.draw_raffle_random_secure(uuid) to authenticated;
