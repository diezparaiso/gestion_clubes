-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Corrige destinatarios de notificaciones según los roles reales del esquema.
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
begin
  select n.club_id
    into v_club_id
  from public.notifications n
  where n.id = p_notification_id;

  if v_club_id is null then
    raise exception 'Notificación no encontrada';
  end if;

  if not public.is_club_manager(v_club_id) then
    raise exception 'Solo managers pueden entregar notificaciones';
  end if;

  if p_target not in ('all_members', 'managers', 'members', 'staff') then
    raise exception 'Target inválido: %', p_target;
  end if;

  insert into public.notification_deliveries (notification_id, profile_id)
  select p_notification_id, cm.profile_id
  from public.club_memberships cm
  where cm.club_id = v_club_id
    and cm.is_active
    and (
      p_target = 'all_members'
      or (p_target = 'managers' and cm.role in ('club_president', 'club_secretary'))
      or (p_target = 'members' and cm.role = 'member')
    )
  on conflict (notification_id, profile_id) do nothing;

  if p_target = 'staff' then
    insert into public.notification_deliveries (notification_id, profile_id)
    select distinct p_notification_id, ts.profile_id
    from public.team_staff ts
    join public.teams t on t.id = ts.team_id
    where t.club_id = v_club_id
      and ts.is_active
    on conflict (notification_id, profile_id) do nothing;
  end if;
end;
$$;

revoke all on function public.deliver_notification(uuid, text) from public;
grant execute on function public.deliver_notification(uuid, text) to authenticated;
