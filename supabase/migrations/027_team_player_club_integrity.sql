-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Refuerza integridad entre club, equipo y jugador.
-- Impide que team_players relacione un equipo y un jugador de clubes distintos.

create or replace function public.validate_team_player_club_integrity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_team_club uuid;
  v_player_club uuid;
begin
  select club_id into v_team_club from public.teams where id = new.team_id;
  select club_id into v_player_club from public.players where id = new.player_id;

  if v_team_club is null or v_player_club is null then
    raise exception 'Equipo o jugador no existe';
  end if;

  if new.club_id <> v_team_club or new.club_id <> v_player_club then
    raise exception 'Equipo y jugador no pertenecen al club indicado';
  end if;

  return new;
end;
$$;

drop trigger if exists team_players_club_integrity on public.team_players;
create trigger team_players_club_integrity
before insert or update of club_id, team_id, player_id
on public.team_players
for each row execute function public.validate_team_player_club_integrity();

revoke all on function public.validate_team_player_club_integrity() from public;
grant execute on function public.validate_team_player_club_integrity() to authenticated;
