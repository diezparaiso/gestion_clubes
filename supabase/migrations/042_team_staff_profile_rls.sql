-- MODIFICADO POR GPT-5.6 LUNA (2026-09-27): permite a roles con teams_view leer perfiles vinculados a personal de sus equipos.
-- MODIFICADO POR GPT-5.6 LUNA (2026-09-27): resuelve cuentas de personal por email mediante RPC protegido por teams_manage.
-- No se ejecuta automáticamente sobre Supabase remoto.

drop policy if exists profiles_select_team_staff_view on public.profiles;
create policy profiles_select_team_staff_view on public.profiles
for select to authenticated
using (
  exists (
    select 1
    from public.team_staff ts
    where ts.profile_id = profiles.id
      and public.has_club_permission(ts.club_id, 'teams_view')
  )
);

create or replace function public.find_profile_for_team_staff(
  target_club_id uuid,
  target_email text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  found_profile public.profiles%rowtype;
begin
  if not public.has_club_permission(target_club_id, 'teams_manage') then
    raise exception 'No tienes permiso para gestionar personal';
  end if;

  select *
  into found_profile
  from public.profiles
  where lower(email) = lower(trim(target_email))
  limit 1;

  if found_profile.id is null then
    return null;
  end if;

  return jsonb_build_object('id', found_profile.id);
end;
$$;

revoke all on function public.find_profile_for_team_staff(uuid, text) from public;
grant execute on function public.find_profile_for_team_staff(uuid, text) to authenticated;
