-- MODIFICADO POR GITHUB COPILOT (2026-10-05): endurece privilegios y RPC públicas.
-- Preparada para revisión; no ejecutar desde esta sesión.

-- Remove inherited/table and column SELECT grants from anon/PUBLIC on sensitive tables.
do $$
declare
  v_table_name text;
  v_columns text;
  v_existing_select jsonb;
  v_grant record;
begin
  select coalesce(
    jsonb_agg(jsonb_build_object(
      'table_name', c.table_name,
      'column_name', c.column_name,
      'role_name', r.role_name
    )),
    '[]'::jsonb
  )
    into v_existing_select
  from information_schema.columns c
  cross join (values ('authenticated'), ('service_role')) as r(role_name)
  where c.table_schema = 'public'
    and c.table_name = any(array[
      'clubs', 'profiles', 'club_memberships', 'notifications',
      'notification_deliveries', 'user_devices', 'memberships', 'raffles',
      'sponsors', 'raffle_tickets', 'audit_logs'
    ])
    and has_column_privilege(
      r.role_name, format('public.%I', c.table_name), c.column_name, 'SELECT'
    );

  foreach v_table_name in array array[
    'clubs', 'profiles', 'club_memberships', 'notifications',
    'notification_deliveries', 'user_devices', 'memberships', 'raffles',
    'sponsors', 'raffle_tickets', 'audit_logs'
  ] loop
    select string_agg(format('%I', column_name), ', ' order by ordinal_position)
      into v_columns
    from information_schema.columns
    where table_schema = 'public' and table_name = v_table_name;
    if v_columns is null then
      raise exception 'Expected security table public.% does not exist', v_table_name;
    end if;
    execute format('revoke select (%s) on table public.%I from anon, public', v_columns, v_table_name);
    execute format('revoke select on table public.%I from anon, public', v_table_name);
  end loop;

  -- Preserve exactly the effective pre-migration SELECT columns for application roles.
  for v_grant in
    select value from jsonb_array_elements(v_existing_select)
  loop
    execute format(
      'grant select (%I) on table public.%I to %I',
      v_grant.value ->> 'column_name',
      v_grant.value ->> 'table_name',
      v_grant.value ->> 'role_name'
    );
  end loop;
end;
$$;

-- Public raffle pages join clubs directly; expose only the identity fields they select.
grant select (id, public_name, slug) on table public.clubs to anon;
grant select (
  id, title, description, image_url, ticket_price, total_numbers, status,
  end_at, slug, raffle_type, winning_number, monthly_day, subscription_enabled
) on table public.raffles to anon;

-- Authenticated profile consumers need identity fields, not full profile rows.
do $$
declare
  v_columns text;
begin
  select string_agg(format('%I', column_name), ', ' order by ordinal_position)
    into v_columns
    from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles';
  execute format('revoke select (%s) on table public.profiles from authenticated', v_columns);
end;
$$;
revoke select on table public.profiles from authenticated;
grant select (id, first_name, last_name, email, must_change_password)
  on table public.profiles to authenticated;

-- Public sponsor responses must not contain contact data. The return type changed.
drop function if exists public.get_public_sponsors(text);
create function public.get_public_sponsors(target_club_slug text)
returns table (id uuid, name text, logo_url text, website text)
language sql stable security definer set search_path = public
as $$
  select s.id, s.name, s.logo_url, s.website
  from public.sponsors s
  join public.clubs c on c.id = s.club_id
  where c.slug::text = lower(target_club_slug)
    and c.status = 'active'
    and s.status = 'active'
    and s.is_public = true
    and s.contract_start_date <= current_date
    and s.contract_end_date >= current_date
  order by s.name asc;
$$;
revoke all on function public.get_public_sponsors(text) from public, anon, authenticated;
grant execute on function public.get_public_sponsors(text) to anon, authenticated;

-- Profile lookup RPCs return only an ID and retain their permission gates.
create or replace function public.find_profile_for_player(target_club_id uuid, target_email text)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  found_profile_id uuid;
begin
  if not public.has_club_permission(target_club_id, 'players_manage'::public.club_permission) then
    raise exception 'No tienes permiso para gestionar jugadores';
  end if;
  select p.id into found_profile_id
  from public.profiles p
  where lower(p.email) = lower(trim(target_email))
  limit 1;
  if found_profile_id is null then return null; end if;
  return jsonb_build_object('id', found_profile_id);
end;
$$;
revoke all on function public.find_profile_for_player(uuid, text) from public, anon, authenticated;
grant execute on function public.find_profile_for_player(uuid, text) to authenticated;

create or replace function public.find_profile_for_team_staff(target_club_id uuid, target_email text)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  found_profile_id uuid;
begin
  if not public.has_club_permission(target_club_id, 'teams_manage'::public.club_permission) then
    raise exception 'No tienes permiso para gestionar personal';
  end if;
  select p.id into found_profile_id
  from public.profiles p
  where lower(p.email) = lower(trim(target_email))
  limit 1;
  if found_profile_id is null then return null; end if;
  return jsonb_build_object('id', found_profile_id);
end;
$$;
revoke all on function public.find_profile_for_team_staff(uuid, text) from public, anon, authenticated;
grant execute on function public.find_profile_for_team_staff(uuid, text) to authenticated;

-- Notification visibility follows per-user deliveries. The target is materialized
-- atomically on insert so a row cannot be read just by holding notifications_view.
drop policy if exists notifications_select_member on public.notifications;
drop policy if exists notifications_select_permission on public.notifications;
drop policy if exists notifications_select_recipient on public.notifications;
drop policy if exists notifications_manage_manager on public.notifications;
create policy notifications_select_recipient on public.notifications
for select to authenticated
using (exists (
  select 1 from public.notification_deliveries d
  where d.notification_id = notifications.id and d.profile_id = auth.uid()
));
create policy notifications_insert_manager on public.notifications
for insert to authenticated with check (public.is_club_manager(club_id));
create policy notifications_update_manager on public.notifications
for update to authenticated
using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));
create policy notifications_delete_manager on public.notifications
for delete to authenticated using (public.is_club_manager(club_id));

drop policy if exists notification_deliveries_insert_manager on public.notification_deliveries;
revoke select on table public.notifications from authenticated;
do $$
declare
  v_table_name text;
  v_columns text;
begin
  foreach v_table_name in array array['notifications', 'notification_deliveries'] loop
    select string_agg(format('%I', column_name), ', ' order by ordinal_position)
      into v_columns
    from information_schema.columns
    where table_schema = 'public' and table_name = v_table_name;
    execute format(
      'revoke select (%s) on table public.%I from authenticated',
      v_columns,
      v_table_name
    );
  end loop;
end;
$$;
grant select (id, club_id, title, body, type, target, created_at)
  on table public.notifications to authenticated;
revoke insert, update, delete on table public.notifications from authenticated;
grant insert (club_id, title, body, type, target)
  on table public.notifications to authenticated;

revoke select on table public.notification_deliveries from authenticated;
grant select (id, notification_id, profile_id, read_at, created_at)
  on table public.notification_deliveries to authenticated;
revoke insert, update, delete on table public.notification_deliveries from authenticated;

create or replace function public.create_notification_deliveries()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is not null and new.target <> 'profile' then
    insert into public.notification_deliveries (notification_id, profile_id)
    values (new.id, auth.uid())
    on conflict (notification_id, profile_id) do nothing;
  end if;

  if new.target = 'all_members' then
    insert into public.notification_deliveries (notification_id, profile_id)
    select new.id, cm.profile_id from public.club_memberships cm
    where cm.club_id = new.club_id and cm.is_active
    on conflict (notification_id, profile_id) do nothing;
  elsif new.target = 'managers' then
    insert into public.notification_deliveries (notification_id, profile_id)
    select new.id, cm.profile_id from public.club_memberships cm
    where cm.club_id = new.club_id and cm.is_active
      and cm.role in ('club_president'::public.club_role, 'club_secretary'::public.club_role)
    on conflict (notification_id, profile_id) do nothing;
  elsif new.target = 'members' then
    insert into public.notification_deliveries (notification_id, profile_id)
    select new.id, cm.profile_id from public.club_memberships cm
    where cm.club_id = new.club_id and cm.is_active and cm.role = 'member'::public.club_role
    on conflict (notification_id, profile_id) do nothing;
  elsif new.target = 'staff' then
    insert into public.notification_deliveries (notification_id, profile_id)
    select distinct new.id, ts.profile_id from public.team_staff ts
    where ts.club_id = new.club_id and ts.is_active
    on conflict (notification_id, profile_id) do nothing;
  end if;
  return new;
end;
$$;
revoke all on function public.create_notification_deliveries() from public, anon, authenticated;
drop trigger if exists notifications_create_deliveries on public.notifications;
create trigger notifications_create_deliveries
  after insert on public.notifications
  for each row execute function public.create_notification_deliveries();

-- Backfill prior group notifications so the new recipient-only policy preserves history.
insert into public.notification_deliveries (notification_id, profile_id)
select n.id, cm.profile_id
from public.notifications n
join public.club_memberships cm on cm.club_id = n.club_id and cm.is_active
where n.target = 'all_members'
  or (n.target = 'managers' and cm.role in ('club_president'::public.club_role, 'club_secretary'::public.club_role))
  or (n.target = 'members' and cm.role = 'member'::public.club_role)
on conflict (notification_id, profile_id) do nothing;
insert into public.notification_deliveries (notification_id, profile_id)
select distinct n.id, ts.profile_id
from public.notifications n
join public.team_staff ts on ts.club_id = n.club_id and ts.is_active
where n.target = 'staff'
on conflict (notification_id, profile_id) do nothing;

create or replace function public.deliver_notification(p_notification_id uuid, p_target text)
returns void language plpgsql security definer set search_path = public
as $$
declare
  v_club_id uuid;
  v_stored_target text;
begin
  select n.club_id, n.target into v_club_id, v_stored_target
  from public.notifications n where n.id = p_notification_id;
  if v_club_id is null then raise exception 'Notificación no encontrada'; end if;
  if not public.is_club_manager(v_club_id) then
    raise exception 'Solo managers pueden entregar notificaciones';
  end if;
  if p_target is distinct from v_stored_target then
    raise exception 'El destinatario no coincide con el target de la notificación';
  end if;
  if p_target not in ('all_members', 'managers', 'members', 'staff') then
    raise exception 'Target inválido: %', p_target;
  end if;

  if p_target = 'all_members' then
    insert into public.notification_deliveries (notification_id, profile_id)
    select p_notification_id, cm.profile_id from public.club_memberships cm
    where cm.club_id = v_club_id and cm.is_active
    on conflict (notification_id, profile_id) do nothing;
  elsif p_target = 'managers' then
    insert into public.notification_deliveries (notification_id, profile_id)
    select p_notification_id, cm.profile_id from public.club_memberships cm
    where cm.club_id = v_club_id and cm.is_active
      and cm.role in ('club_president'::public.club_role, 'club_secretary'::public.club_role)
    on conflict (notification_id, profile_id) do nothing;
  elsif p_target = 'members' then
    insert into public.notification_deliveries (notification_id, profile_id)
    select p_notification_id, cm.profile_id from public.club_memberships cm
    where cm.club_id = v_club_id and cm.is_active and cm.role = 'member'::public.club_role
    on conflict (notification_id, profile_id) do nothing;
  else
    insert into public.notification_deliveries (notification_id, profile_id)
    select distinct p_notification_id, ts.profile_id from public.team_staff ts
    where ts.club_id = v_club_id and ts.is_active
    on conflict (notification_id, profile_id) do nothing;
  end if;
end;
$$;
revoke all on function public.deliver_notification(uuid, text) from public, anon, authenticated;
grant execute on function public.deliver_notification(uuid, text) to authenticated;

-- buyer_profile_id is the original ownership field; 036's profile_id is kept
-- synchronized. Abort instead of silently choosing an owner if data conflicts.
do $$
begin
  if exists (
    select 1 from public.raffle_tickets
    where buyer_profile_id is not null and profile_id is not null
      and buyer_profile_id <> profile_id
  ) then
    raise exception 'raffle_tickets has conflicting buyer_profile_id/profile_id values; reconcile those rows before applying 047';
  end if;
end;
$$;
update public.raffle_tickets
set buyer_profile_id = profile_id
where buyer_profile_id is null and profile_id is not null;
update public.raffle_tickets
set profile_id = buyer_profile_id
where profile_id is null and buyer_profile_id is not null;
alter table public.raffle_tickets
  drop constraint if exists raffle_tickets_profile_owner_consistency;
alter table public.raffle_tickets
  add constraint raffle_tickets_profile_owner_consistency
  check (profile_id is null or buyer_profile_id is null or profile_id = buyer_profile_id);

drop policy if exists raffle_tickets_select_manager on public.raffle_tickets;
drop policy if exists raffle_tickets_receipt_owner_select on public.raffle_tickets;
drop policy if exists raffle_tickets_select_permission on public.raffle_tickets;
create policy raffle_tickets_select_permission on public.raffle_tickets
for select to authenticated
using (public.has_club_permission(club_id, 'raffles_view'::public.club_permission) or buyer_profile_id = auth.uid());

-- Serialize public reservations with draws by locking the same raffle row.
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
  v_raffle_id uuid;
  v_club_id uuid;
  v_total_numbers integer;
  selected_number integer;
begin
  if coalesce(array_length(selected_numbers, 1), 0) < 1
     or array_length(selected_numbers, 1) > 10 then
    raise exception 'Selecciona entre 1 y 10 números';
  end if;
  if trim(coalesce(target_buyer_name, '')) = ''
     or position('@' in coalesce(target_buyer_email, '')) < 2 then
    raise exception 'Los datos del comprador no son válidos';
  end if;

  select r.id, r.club_id, r.total_numbers
    into v_raffle_id, v_club_id, v_total_numbers
  from public.raffles r
  join public.clubs c on c.id = r.club_id
  where c.slug::text = lower(target_club_slug)
    and r.slug::text = lower(target_raffle_slug)
    and r.status = 'active'
    and r.end_at > timezone('utc', now())
  for update of r;
  if not found then raise exception 'La rifa no está disponible'; end if;

  delete from public.raffle_tickets
  where raffle_id = v_raffle_id
    and payment_status = 'pending'
    and reservation_expires_at <= timezone('utc', now());

  foreach selected_number in array selected_numbers loop
    if selected_number < 1 or selected_number > v_total_numbers then
      raise exception 'Número de rifa no válido';
    end if;
    if exists (
      select 1 from public.raffle_tickets t
      where t.raffle_id = v_raffle_id
        and t.number = selected_number
        and (
          t.payment_status = 'paid'
          or (t.payment_status = 'pending' and t.reservation_expires_at > timezone('utc', now()))
        )
    ) then
      raise exception 'Uno de los números seleccionados ya no está disponible';
    end if;
    insert into public.raffle_tickets (
      club_id, raffle_id, number, buyer_name, buyer_email, buyer_phone,
      payment_status, reservation_expires_at
    ) values (
      v_club_id, v_raffle_id, selected_number,
      trim(target_buyer_name), lower(trim(target_buyer_email)),
      nullif(trim(target_buyer_phone), ''), 'pending',
      timezone('utc', now()) + interval '15 minutes'
    );
  end loop;
  return selected_numbers;
end;
$$;
revoke all on function public.reserve_public_raffle_numbers(text, text, integer[], text, text, text)
  from public, anon, authenticated;
grant execute on function public.reserve_public_raffle_numbers(text, text, integer[], text, text, text)
  to anon, authenticated;

create or replace function public.set_raffle_manual_winner(target_raffle_id uuid, target_winning_number integer)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_club_id uuid;
  v_raffle_type text;
  v_end_at timestamptz;
  v_total_numbers integer;
  v_winning_number integer;
  v_status public.raffle_status;
  v_title text;
  v_ticket_id uuid;
  v_buyer_email citext;
  v_winner_profile_id uuid;
  v_notification_id uuid;
begin
  select r.club_id, r.raffle_type, r.end_at, r.total_numbers,
         r.winning_number, r.status, r.title
    into v_club_id, v_raffle_type, v_end_at, v_total_numbers,
         v_winning_number, v_status, v_title
  from public.raffles r where r.id = target_raffle_id for update;
  if not found then raise exception 'Rifa no encontrada'; end if;
  if not public.has_club_permission(v_club_id, 'raffles_manage'::public.club_permission) then
    raise exception 'No tienes permiso para gestionar rifas';
  end if;
  if v_raffle_type <> 'cesta' then
    raise exception 'Esta operación solo está disponible para rifas tipo Cesta';
  end if;
  if v_status not in ('active', 'closed') then
    raise exception 'La rifa no está disponible para elegir ganador';
  end if;
  if v_winning_number is not null or v_status = 'drawn' then
    raise exception 'La rifa ya ha sido sorteada';
  end if;
  if now() < v_end_at then raise exception 'La rifa todavía no ha terminado'; end if;
  if target_winning_number < 1 or target_winning_number > v_total_numbers then
    raise exception 'Número ganador fuera de rango';
  end if;

  select t.id, t.buyer_email into v_ticket_id, v_buyer_email
  from public.raffle_tickets t
  where t.raffle_id = target_raffle_id
    and t.number = target_winning_number
    and t.payment_status = 'paid'
  for update;
  if not found then
    raise exception 'El número ganador debe estar entre las participaciones confirmadas';
  end if;

  update public.raffles
  set winning_number = target_winning_number, status = 'drawn'
  where id = target_raffle_id;
  select p.id into v_winner_profile_id
  from public.profiles p
  where lower(p.email) = lower(v_buyer_email::text)
  limit 1;

  if v_winner_profile_id is not null then
    insert into public.notifications (club_id, title, body, type, target)
    values (v_club_id, '¡Has ganado la rifa!',
      'El número ' || target_winning_number || ' ha resultado agraciado en ' || v_title || '.',
      'raffle_winner', 'profile')
    returning id into v_notification_id;
    insert into public.notification_deliveries (notification_id, profile_id)
    values (v_notification_id, v_winner_profile_id)
    on conflict (notification_id, profile_id) do nothing;
  end if;

  insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
  values (v_club_id, auth.uid(), 'raffle_draw', 'raffle', target_raffle_id,
    jsonb_build_object('draw_method', 'manual', 'winning_number', target_winning_number,
      'raffle_type', v_raffle_type, 'ticket_id', v_ticket_id));
  return jsonb_build_object('id', gen_random_uuid(), 'raffle_id', target_raffle_id,
    'winning_number', target_winning_number, 'drawn_at', now(), 'method', 'president_selected');
end;
$$;
revoke all on function public.set_raffle_manual_winner(uuid, integer) from public, anon, authenticated;
grant execute on function public.set_raffle_manual_winner(uuid, integer) to authenticated;

create or replace function public.draw_raffle_random_secure(target_raffle_id uuid)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_club_id uuid;
  v_raffle_type text;
  v_end_at timestamptz;
  v_winning_number integer;
  v_status public.raffle_status;
  v_chosen_number integer;
  v_count_numbers integer;
  v_raw_value bigint;
  v_limit_value bigint;
begin
  select r.club_id, r.raffle_type, r.end_at, r.winning_number, r.status
    into v_club_id, v_raffle_type, v_end_at, v_winning_number, v_status
  from public.raffles r where r.id = target_raffle_id for update;
  if not found then raise exception 'Rifa no encontrada'; end if;
  if not public.has_club_permission(v_club_id, 'raffles_manage'::public.club_permission) then
    raise exception 'No tienes permiso para gestionar rifas';
  end if;
  if v_raffle_type <> 'sorteoPuro' then
    raise exception 'Esta rifa requiere selección manual del ganador';
  end if;
  if v_winning_number is not null or v_status = 'drawn' then
    raise exception 'La rifa ya ha sido sorteada';
  end if;
  if v_status not in ('active', 'closed') then
    raise exception 'La rifa no está disponible para el sorteo';
  end if;
  if now() < v_end_at then raise exception 'La rifa todavía no ha terminado'; end if;

  perform 1
  from public.raffle_tickets t
  where t.raffle_id = target_raffle_id
  order by t.number
  for update;
  select count(*) into v_count_numbers
  from public.raffle_tickets t
  where t.raffle_id = target_raffle_id and t.payment_status = 'paid';
  if v_count_numbers = 0 then raise exception 'No hay participaciones confirmadas'; end if;

  loop
    v_raw_value := ('x' || encode(gen_random_bytes(8), 'hex'))::bit(64)::bigint;
    v_raw_value := v_raw_value & 9223372036854775807;
    v_limit_value := 9223372036854775807 - mod(9223372036854775807, v_count_numbers);
    exit when v_raw_value < v_limit_value;
  end loop;
  select q.number into v_chosen_number
  from (
    select t.number, row_number() over (order by t.number) - 1 as idx
    from public.raffle_tickets t
    where t.raffle_id = target_raffle_id and t.payment_status = 'paid'
  ) q
  where q.idx = mod(v_raw_value, v_count_numbers);

  update public.raffles
  set winning_number = v_chosen_number, status = 'drawn'
  where id = target_raffle_id;
  insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
  values (v_club_id, auth.uid(), 'raffle_draw', 'raffle', target_raffle_id,
    jsonb_build_object('draw_method', 'cryptographic_random', 'winning_number', v_chosen_number,
      'raffle_type', v_raffle_type, 'random_source', 'pgcrypto'));
  return jsonb_build_object('id', gen_random_uuid(), 'raffle_id', target_raffle_id,
    'winning_number', v_chosen_number, 'drawn_at', now(), 'method', 'cryptographic_random');
end;
$$;
revoke all on function public.draw_raffle_random_secure(uuid) from public, anon, authenticated;
grant execute on function public.draw_raffle_random_secure(uuid) to authenticated;

-- Preserve service-role-only payment confirmation while synchronizing owner IDs.
create or replace function public.record_raffle_payment(
  target_ticket_id uuid,
  target_profile_id uuid,
  target_payment_reference text
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_raffle_id uuid;
  v_number integer;
  v_payment_status public.ticket_payment_status;
  v_existing_profile_id uuid;
  v_receipt text;
begin
  if auth.role() <> 'service_role' then
    raise exception 'Esta operación solo puede ejecutarse desde el backend de pagos';
  end if;
  if target_profile_id is null then raise exception 'El perfil comprador es obligatorio'; end if;

  select t.raffle_id, t.number, t.payment_status,
         coalesce(t.buyer_profile_id, t.profile_id)
    into v_raffle_id, v_number, v_payment_status, v_existing_profile_id
  from public.raffle_tickets t where t.id = target_ticket_id for update;
  if not found then raise exception 'Participación no encontrada'; end if;
    if v_payment_status = 'paid'
      and v_existing_profile_id is not null
     and v_existing_profile_id is distinct from target_profile_id then
    raise exception 'La participación ya está asociada a otro perfil';
  end if;

  v_receipt := 'RIFA-' || upper(substr(replace(target_ticket_id::text, '-', ''), 1, 12));
  update public.raffle_tickets
  set buyer_profile_id = target_profile_id,
      profile_id = target_profile_id,
      payment_reference = nullif(trim(target_payment_reference), ''),
      payment_status = 'paid',
      paid_at = coalesce(paid_at, now()),
      receipt_number = coalesce(receipt_number, v_receipt)
  where id = target_ticket_id;

  return jsonb_build_object('ticket_id', target_ticket_id, 'raffle_id', v_raffle_id,
    'number', v_number, 'payment_reference', target_payment_reference,
    'receipt_number', v_receipt);
end;
$$;
revoke all on function public.record_raffle_payment(uuid, uuid, text) from public, anon, authenticated, service_role;
grant execute on function public.record_raffle_payment(uuid, uuid, text) to service_role;
