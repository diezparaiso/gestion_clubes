-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): completa las operaciones seguras de cambio de rol.
-- No se ejecuta automáticamente sobre Supabase remoto.

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
begin
  if not public.has_club_permission(p_club_id, 'access_manage') then
    return query select false, 'No tienes permiso para gestionar accesos'::text;
    return;
  end if;

  if p_role = 'club_president' and not public.is_platform_admin() then
    -- Un presidente puede nombrar otro presidente, pero no dejar el club sin presidente.
    null;
  end if;

  select exists(
    select 1 from public.club_memberships
    where club_id = p_club_id and profile_id = p_profile_id and is_active = true
  ) into v_target_exists;

  if not v_target_exists then
    return query select false, 'El usuario no tiene un acceso activo en este club'::text;
    return;
  end if;

  update public.club_memberships
  set role = p_role
  where club_id = p_club_id
    and profile_id = p_profile_id
    and is_active = true;

  insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
  values (
    p_club_id, auth.uid(), 'permission_change', 'club_membership', p_profile_id,
    jsonb_build_object('action', 'role_change', 'new_role', p_role::text)
  );

  return query select true, 'Rol actualizado'::text;
end;
$$;

revoke all on function public.change_member_role(uuid, uuid, public.club_role) from public;
grant execute on function public.change_member_role(uuid, uuid, public.club_role) to authenticated;
