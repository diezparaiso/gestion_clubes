-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): endurece cambios de rol y protege al presidente del club.
-- No se ejecuta automáticamente sobre Supabase remoto.

drop function if exists public.change_member_role(uuid, uuid, public.club_role);

create or replace function public.change_member_role(
  p_club_id uuid,
  p_profile_id uuid,
  p_role public.club_role
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_target_exists boolean;
  v_target_role public.club_role;
  v_actor_profile uuid := auth.uid();
  v_active_presidents integer;
begin
  if not public.has_club_permission(p_club_id, 'access_manage') then
    return query select false, 'No tienes permiso para gestionar accesos'::text;
    return;
  end if;

  select cm.role into v_target_role
  from public.club_memberships cm
  where cm.club_id = p_club_id
    and cm.profile_id = p_profile_id
    and cm.is_active = true
  for update;

  if v_target_role is null then
    return query select false, 'El usuario no tiene un acceso activo en este club'::text;
    return;
  end if;

  if p_role = 'club_president' and not public.is_platform_admin() then
    return query select false, 'Solo un administrador de plataforma puede nombrar otro presidente'::text;
    return;
  end if;

  if v_target_role = 'club_president' and p_role <> 'club_president' then
    select count(*) into v_active_presidents
    from public.club_memberships
    where club_id = p_club_id
      and role = 'club_president'
      and is_active = true;

    if v_active_presidents <= 1 then
      return query select false, 'El club debe conservar al menos un presidente activo'::text;
      return;
    end if;
  end if;

  update public.club_memberships
  set role = p_role
  where club_id = p_club_id
    and profile_id = p_profile_id
    and is_active = true;

  insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
  values (
    p_club_id,
    v_actor_profile,
    'permission_change',
    'club_membership',
    p_profile_id,
    jsonb_build_object(
      'action', 'role_change',
      'previous_role', v_target_role::text,
      'new_role', p_role::text
    )
  );

  return query select true, 'Rol actualizado'::text;
end;
$$;

revoke all on function public.change_member_role(uuid, uuid, public.club_role) from public;
grant execute on function public.change_member_role(uuid, uuid, public.club_role) to authenticated;
