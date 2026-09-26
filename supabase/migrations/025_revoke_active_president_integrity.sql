-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Impide revocar al único presidente activo del club.
-- Corrige la lógica histórica de revoke_member_access, que contaba también memberships inactivas.

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
  v_active_presidents integer;
begin
  if not public.is_club_manager(p_club_id) then
    return query select false, 'Solo managers pueden revocar acceso'::text;
    return;
  end if;

  select (role = 'club_president')
    into v_was_president
  from public.club_memberships
  where club_id = p_club_id
    and profile_id = p_profile_id
    and is_active = true
  order by created_at desc
  limit 1;

  if coalesce(v_was_president, false) then
    select count(*)
      into v_active_presidents
    from public.club_memberships
    where club_id = p_club_id
      and role = 'club_president'
      and is_active = true;

    if v_active_presidents <= 1 then
      return query select false, 'No puedes revocar al único presidente activo'::text;
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
