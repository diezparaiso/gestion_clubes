-- MODIFICADO POR GPT-5.6 LUNA (2026-09-29): alinea RLS de módulos internos
-- con public.club_role_permissions / public.has_club_permission.
-- No se ejecuta automáticamente sobre Supabase remoto.
--
-- Objetivo: impedir que is_club_manager (presidente + secretario) otorgue
-- implícitamente permisos de gestión que la matriz central no contempla.
-- La UI ya oculta estas acciones; esta migración lleva la misma frontera al
-- backend/RLS.

-- Socios
drop policy if exists memberships_select_member on public.memberships;
drop policy if exists memberships_select_permission on public.memberships;
create policy memberships_select_permission on public.memberships
for select to authenticated
using (public.has_club_permission(club_id, 'members_view'));

drop policy if exists memberships_insert_manager on public.memberships;
create policy memberships_insert_permission on public.memberships
for insert to authenticated
with check (public.has_club_permission(club_id, 'members_manage'));

drop policy if exists memberships_update_manager on public.memberships;
create policy memberships_update_permission on public.memberships
for update to authenticated
using (public.has_club_permission(club_id, 'members_manage'))
with check (public.has_club_permission(club_id, 'members_manage'));

-- Club / configuración
drop policy if exists clubs_update_manager on public.clubs;
create policy clubs_update_permission on public.clubs
for update to authenticated
using (public.has_club_permission(id, 'club_settings_manage'))
with check (public.has_club_permission(id, 'club_settings_manage'));

-- Temporadas y equipos
drop policy if exists seasons_manage_manager on public.seasons;
create policy seasons_manage_permission on public.seasons
for all to authenticated
using (public.has_club_permission(club_id, 'teams_manage'))
with check (public.has_club_permission(club_id, 'teams_manage'));

drop policy if exists teams_manage_manager on public.teams;
create policy teams_manage_permission on public.teams
for all to authenticated
using (public.has_club_permission(club_id, 'teams_manage'))
with check (public.has_club_permission(club_id, 'teams_manage'));

-- Jugadores
drop policy if exists players_manage_manager on public.players;
create policy players_manage_permission on public.players
for all to authenticated
using (public.has_club_permission(club_id, 'players_manage'))
with check (public.has_club_permission(club_id, 'players_manage'));

drop policy if exists team_players_manage_manager on public.team_players;
create policy team_players_manage_permission on public.team_players
for all to authenticated
using (public.has_club_permission(club_id, 'players_manage'))
with check (public.has_club_permission(club_id, 'players_manage'));

-- Personal de equipos
drop policy if exists team_staff_manage_manager on public.team_staff;
create policy team_staff_manage_permission on public.team_staff
for all to authenticated
using (public.has_club_permission(club_id, 'teams_manage'))
with check (public.has_club_permission(club_id, 'teams_manage'));

-- Tesorería
drop policy if exists financial_accounts_select_manager on public.financial_accounts;
create policy financial_accounts_select_permission on public.financial_accounts
for select to authenticated
using (public.has_club_permission(club_id, 'finance_view'));

drop policy if exists financial_accounts_manage_manager on public.financial_accounts;
create policy financial_accounts_manage_permission on public.financial_accounts
for all to authenticated
using (public.has_club_permission(club_id, 'finance_manage'))
with check (public.has_club_permission(club_id, 'finance_manage'));

drop policy if exists financial_transactions_select_manager on public.financial_transactions;
create policy financial_transactions_select_permission on public.financial_transactions
for select to authenticated
using (public.has_club_permission(club_id, 'finance_view'));

drop policy if exists financial_transactions_insert_manager on public.financial_transactions;
create policy financial_transactions_insert_permission on public.financial_transactions
for insert to authenticated
with check (
  public.has_club_permission(club_id, 'finance_manage')
  and created_by = auth.uid()
);

drop policy if exists financial_transactions_update_manager on public.financial_transactions;
create policy financial_transactions_update_permission on public.financial_transactions
for update to authenticated
using (public.has_club_permission(club_id, 'finance_manage'))
with check (
  public.has_club_permission(club_id, 'finance_manage')
  and created_by = auth.uid()
);

-- Rifas
drop policy if exists raffles_manage_manager on public.raffles;
create policy raffles_manage_permission on public.raffles
for all to authenticated
using (public.has_club_permission(club_id, 'raffles_manage'))
with check (public.has_club_permission(club_id, 'raffles_manage'));

-- Noticias
drop policy if exists posts_manage_manager on public.posts;
create policy posts_manage_permission on public.posts
for all to authenticated
using (public.has_club_permission(club_id, 'news_manage'))
with check (public.has_club_permission(club_id, 'news_manage'));

-- Eventos
drop policy if exists events_manage_manager on public.events;
create policy events_manage_permission on public.events
for all to authenticated
using (public.has_club_permission(club_id, 'events_manage'))
with check (public.has_club_permission(club_id, 'events_manage'));

-- Accesos: lectura limitada a los propios accesos o a access_manage.
drop policy if exists club_memberships_select_member on public.club_memberships;
drop policy if exists club_memberships_select_own_or_access on public.club_memberships;
create policy club_memberships_select_own_or_access on public.club_memberships
for select to authenticated
using (
  profile_id = auth.uid()
  or public.has_club_permission(club_id, 'access_manage')
);

drop policy if exists club_memberships_manage_manager on public.club_memberships;
create policy club_memberships_manage_permission on public.club_memberships
for all to authenticated
using (public.has_club_permission(club_id, 'access_manage'))
with check (public.has_club_permission(club_id, 'access_manage'));

-- Perfiles: un gestor de socios puede consultar perfiles necesarios para el
-- listado de socios; no se amplía el acceso de perfiles a otros roles.
drop policy if exists profiles_select_club_manager on public.profiles;
create policy profiles_select_members_manager on public.profiles
for select to authenticated
using (
  id = auth.uid()
  or exists (
    select 1
    from public.memberships m
    where m.profile_id = profiles.id
      and public.has_club_permission(m.club_id, 'members_view')
  )
);

-- La lectura de cada módulo permanece gobernada por las políticas *_view
-- introducidas en 039. Las políticas públicas (anon) de contenidos públicos
-- no se modifican.
