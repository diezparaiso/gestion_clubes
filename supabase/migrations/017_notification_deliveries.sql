-- Tabla de entregas de notificaciones (quién recibe qué)
create table public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.notifications(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  unique(notification_id, profile_id)
);

create index notification_deliveries_profile_idx on public.notification_deliveries (profile_id, created_at desc);
create index notification_deliveries_read_idx on public.notification_deliveries (read_at) where read_at is null;

alter table public.notification_deliveries enable row level security;

-- Solo puedes ver tus propias entregas
create policy notification_deliveries_select_own on public.notification_deliveries 
  for select to authenticated 
  using (profile_id = auth.uid());

-- Managers pueden crear entregas para sus miembros
create policy notification_deliveries_insert_manager on public.notification_deliveries 
  for insert to authenticated 
  with check (
    exists(
      select 1 from public.notifications n
      where n.id = notification_id
      and public.is_club_manager(n.club_id)
    )
  );

-- Marcar como leído
create policy notification_deliveries_update_own on public.notification_deliveries 
  for update to authenticated 
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- RPC para crear entregas en masa (solo managers)
create or replace function public.deliver_notification(
  p_notification_id uuid,
  p_target text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_club_id uuid;
  v_recipient_ids uuid[];
begin
  -- Obtener club_id y verificar permisos
  select n.club_id into v_club_id
  from notifications n
  where n.id = p_notification_id;
  
  if not is_club_manager(v_club_id) then
    raise exception 'Solo managers pueden entregar notificaciones';
  end if;
  
  -- Determinar destinatarios según target
  case p_target
    when 'all_members' then
      select array_agg(cm.profile_id)
      into v_recipient_ids
      from club_memberships cm
      where cm.club_id = v_club_id;
    when 'managers' then
      select array_agg(cm.profile_id)
      into v_recipient_ids
      from club_memberships cm
      where cm.club_id = v_club_id
      and cm.role in ('president', 'manager', 'treasurer');
    when 'staff' then
      select array_agg(distinct ts.profile_id)
      into v_recipient_ids
      from team_staff ts
      join teams t on t.id = ts.team_id
      where t.club_id = v_club_id;
    else
      raise exception 'Target inválido: %', p_target;
  end case;
  
  -- Insertar entregas (ignorar duplicadas)
  insert into notification_deliveries (notification_id, profile_id)
  select p_notification_id, unnest(v_recipient_ids)
  on conflict do nothing;
end;
$$;

revoke all on function public.deliver_notification(uuid, text) from public;
grant execute on function public.deliver_notification(uuid, text) to authenticated;