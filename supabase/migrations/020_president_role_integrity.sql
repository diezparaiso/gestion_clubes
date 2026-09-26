-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Impide dejar un club sin presidente activo al cambiar el rol de otro presidente.
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
  if not public.is_club_manager(p_club_id) then
    return query select false, 'Solo managers pueden cambiar roles'::text;
    return;
  end if;

  select role into v_old_role
  from public.club_memberships
  where club_id = p_club_id and profile_id = p_profile_id and is_active
  order by created_at desc limit 1;

  if v_old_role is null then
    return query select false, 'Usuario no es miembro activo del club'::text;
    return;
  end if;

  if v_old_role = 'club_president' and p_new_role <> 'club_president' then
    if (select count(*) from public.club_memberships
        where club_id = p_club_id and role = 'club_president' and is_active) <= 1 then
      return query select false, 'No puedes quitar el único presidente activo del club'::text;
      return;
    end if;
  end if;

  update public.club_memberships
  set role = p_new_role, is_active = true
  where club_id = p_club_id and profile_id = p_profile_id and role = v_old_role and is_active;

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
