-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Refuerza integridad entre club, equipo y personal.
-- Impide que team_staff relacione un equipo y un perfil de clubes distintos.

create or replace function public.validate_team_staff_club_integrity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_team_club uuid;
  v_profile_exists boolean;
begin
  select club_id into v_team_club from public.teams where id = new.team_id;

  if v_team_club is null then
    raise exception 'El equipo no existe';
  end if;

  if new.club_id <> v_team_club then
    raise exception 'El equipo no pertenece al club indicado';
  end if;

  select exists (
    select 1
    from public.club_memberships cm
    where cm.club_id = new.club_id
      and cm.profile_id = new.profile_id
      and cm.is_active = true
  ) into v_profile_exists;

  if not v_profile_exists then
    raise exception 'El personal debe pertenecer al club activo';
  end if;

  return new;
end;
$$;

drop trigger if exists team_staff_club_integrity on public.team_staff;
create trigger team_staff_club_integrity
before insert or update of club_id, team_id, profile_id
on public.team_staff
for each row execute function public.validate_team_staff_club_integrity();

revoke all on function public.validate_team_staff_club_integrity() from public;
grant execute on function public.validate_team_staff_club_integrity() to authenticated;
