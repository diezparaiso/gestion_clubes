-- MODIFICADO POR GPT-5.6 LUNA (2026-09-27): añade revocación segura de accesos del club.
-- No se ejecuta automáticamente sobre Supabase remoto.

create or replace function public.revoke_member_access(
  p_club_id uuid,
  p_profile_id uuid
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_profile uuid := auth.uid();
  v_target_role public.club_role;
  v_active_presidents integer;
begin
  if not public.has_club_permission(p_club_id, 'access_manage') then
    return query select false, 'No tienes permiso para gestionar accesos'::text;
    return;
  end if;

  select cm.role
    into v_target_role
  from public.club_memberships cm
  where cm.club_id = p_club_id
    and cm.profile_id = p_profile_id
    and cm.is_active = true
  for update;

  if v_target_role is null then
    return query select false, 'El usuario no tiene un acceso activo en este club'::text;
    return;
  end if;

  if v_target_role = 'club_president' then
    select count(*)
      into v_active_presidents
    from public.club_memberships cm
    where cm.club_id = p_club_id
      and cm.role = 'club_president'
      and cm.is_active = true;

    if v_active_presidents <= 1 then
      return query select false, 'El club debe conservar al menos un presidente activo'::text;
      return;
    end if;
  end if;

  update public.club_memberships
  set is_active = false
  where club_id = p_club_id
    and profile_id = p_profile_id
    and is_active = true;

  insert into public.audit_logs (
    club_id,
    actor_profile_id,
    action,
    entity_type,
    entity_id,
    data
  )
  values (
    p_club_id,
    v_actor_profile,
    'permission_change',
    'club_membership',
    p_profile_id,
    jsonb_build_object(
      'action', 'access_revoke',
      'previous_role', v_target_role::text
    )
  );

  return query select true, 'Acceso revocado'::text;
end;
$$;

revoke all on function public.revoke_member_access(uuid, uuid) from public;
grant execute on function public.revoke_member_access(uuid, uuid) to authenticated;
