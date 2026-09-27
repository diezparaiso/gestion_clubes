-- MODIFICADO POR GPT-5.6 LUNA (2026-09-27): alinea la invitación de socios con access_manage.
-- No se ejecuta automáticamente sobre Supabase remoto.

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
begin
  if not public.has_club_permission(p_club_id, 'access_manage') then
    return query select false, 'No tienes permiso para gestionar accesos'::text;
    return;
  end if;

  select id
    into v_target_profile_id
  from public.profiles
  where email = p_email;

  if v_target_profile_id is null then
    return query select false, 'Usuario no registrado'::text;
    return;
  end if;

  if exists (
    select 1
    from public.club_memberships
    where club_id = p_club_id
      and profile_id = v_target_profile_id
      and role = p_role
  ) then
    return query select false, 'Usuario ya tiene este rol'::text;
    return;
  end if;

  insert into public.club_memberships (club_id, profile_id, role, is_active)
  values (p_club_id, v_target_profile_id, p_role, false);

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
    auth.uid(),
    'permission_change',
    'club_membership',
    v_target_profile_id,
    jsonb_build_object(
      'action', 'invite',
      'role', p_role::text,
      'email', p_email::text
    )
  );

  return query select true, 'Invitación enviada'::text;
end;
$$;

revoke all on function public.invite_club_member(uuid, citext, public.club_role) from public;
grant execute on function public.invite_club_member(uuid, citext, public.club_role) to authenticated;
