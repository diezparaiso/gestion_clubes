-- RPC para invitar usuario a club
create or replace function public.invite_club_member(
  p_club_id uuid,
  p_email citext,
  p_role public.club_role
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_target_profile_id uuid;
  v_invite_id uuid;
begin
  -- Verificar que el caller es manager
  if not public.is_club_manager(p_club_id) then
    return query select false, 'Solo managers pueden invitar'::text;
    return;
  end if;

  -- Buscar o crear perfil con ese email
  select id into v_target_profile_id from public.profiles where email = p_email;
  
  if v_target_profile_id is null then
    return query select false, 'Usuario no registrado'::text;
    return;
  end if;

  -- Verificar que no exista ya
  if exists (
    select 1 from public.club_memberships 
    where club_id = p_club_id and profile_id = v_target_profile_id and role = p_role
  ) then
    return query select false, 'Usuario ya tiene este rol'::text;
    return;
  end if;

  -- Insertar nuevo rol
  insert into public.club_memberships (club_id, profile_id, role, is_active)
  values (p_club_id, v_target_profile_id, p_role, false);

  -- Registrar en auditoría
  insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
  values (
    p_club_id,
    auth.uid(),
    'permission_change',
    'club_membership',
    v_target_profile_id,
    jsonb_build_object('action', 'invite', 'role', p_role::text, 'email', p_email::text)
  );

  return query select true, 'Invitación enviada'::text;
end;
$$;

revoke all on function public.invite_club_member(uuid, citext, public.club_role) from public;
grant execute on function public.invite_club_member(uuid, citext, public.club_role) to authenticated;

-- RPC para cambiar rol de miembro
create or replace function public.change_member_role(
  p_club_id uuid,
  p_profile_id uuid,
  p_new_role public.club_role
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old_role public.club_role;
begin
  -- Verificar que el caller es manager
  if not public.is_club_manager(p_club_id) then
    return query select false, 'Solo managers pueden cambiar roles'::text;
    return;
  end if;

  -- No permitir cambiar tu propio rol si eres el único president
  if p_profile_id = auth.uid() and p_new_role != 'club_president' then
    if (select count(*) from public.club_memberships 
        where club_id = p_club_id and role = 'club_president') = 1 then
      return query select false, 'No puedes quitarte el rol de president siendo el único'::text;
      return;
    end if;
  end if;

  -- Obtener rol anterior
  select role into v_old_role from public.club_memberships
  where club_id = p_club_id and profile_id = p_profile_id
  order by created_at desc limit 1;

  if v_old_role is null then
    return query select false, 'Usuario no es miembro del club'::text;
    return;
  end if;

  -- Actualizar rol
  update public.club_memberships
  set role = p_new_role, is_active = true
  where club_id = p_club_id and profile_id = p_profile_id and role = v_old_role;

  -- Registrar en auditoría
  insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
  values (
    p_club_id,
    auth.uid(),
    'permission_change',
    'club_membership',
    p_profile_id,
    jsonb_build_object('old_role', v_old_role::text, 'new_role', p_new_role::text)
  );

  return query select true, 'Rol actualizado'::text;
end;
$$;

revoke all on function public.change_member_role(uuid, uuid, public.club_role) from public;
grant execute on function public.change_member_role(uuid, uuid, public.club_role) to authenticated;

-- RPC para revocar acceso
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
  v_was_president boolean;
begin
  -- Verificar que el caller es manager
  if not public.is_club_manager(p_club_id) then
    return query select false, 'Solo managers pueden revocar acceso'::text;
    return;
  end if;

  -- No permitir revocar si es el único president
  select (role = 'club_president') into v_was_president
  from public.club_memberships
  where club_id = p_club_id and profile_id = p_profile_id
  order by created_at desc limit 1;

  if v_was_president and (select count(*) from public.club_memberships 
      where club_id = p_club_id and role = 'club_president') = 1 then
    return query select false, 'No puedes revocar al único president'::text;
    return;
  end if;

  -- Desactivar
  update public.club_memberships
  set is_active = false
  where club_id = p_club_id and profile_id = p_profile_id;

  -- Registrar en auditoría
  insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
  values (
    p_club_id,
    auth.uid(),
    'permission_change',
    'club_membership',
    p_profile_id,
    jsonb_build_object('action', 'revoke')
  );

  return query select true, 'Acceso revocado'::text;
end;
$$;

revoke all on function public.revoke_member_access(uuid, uuid) from public;
grant execute on function public.revoke_member_access(uuid, uuid) to authenticated;