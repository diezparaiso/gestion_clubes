-- MODIFICADO POR GPT-5.6 LUNA (2026-09-27): alinea RLS con permisos view/manage definidos en 032.
-- No se ejecuta automáticamente sobre Supabase remoto.

-- Identidad y configuración del club.
drop policy if exists clubs_update_manager on public.clubs;
create policy clubs_update_settings_manager on public.clubs
for update to authenticated
using (public.has_club_permission(id, 'club_settings_manage'))
with check (public.has_club_permission(id, 'club_settings_manage'));

drop policy if exists profiles_select_club_manager on public.profiles;
create policy profiles_select_members_view on public.profiles
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

drop policy if exists club_memberships_manage_manager on public.club_memberships;
create policy club_memberships_manage_access on public.club_memberships
for all to authenticated
using (public.has_club_permission(club_id, 'access_manage'))
with check (public.has_club_permission(club_id, 'access_manage'));

-- Socios.
drop policy if exists memberships_insert_manager on public.memberships;
create policy memberships_insert_manage on public.memberships
for insert to authenticated
with check (public.has_club_permission(club_id, 'members_manage'));

drop policy if exists memberships_update_manager on public.memberships;
create policy memberships_update_manage on public.memberships
for update to authenticated
using (public.has_club_permission(club_id, 'members_manage'))
with check (public.has_club_permission(club_id, 'members_manage'));

-- Equipos y temporadas.
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

-- Jugadores.
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

-- Staff de equipos: el modelo actual no define staff_manage; se mantiene bajo teams_manage.
drop policy if exists team_staff_manage_manager on public.team_staff;
create policy team_staff_manage_permission on public.team_staff
for all to authenticated
using (public.has_club_permission(club_id, 'teams_manage'))
with check (public.has_club_permission(club_id, 'teams_manage'));

-- Tesorería.
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
with check (public.has_club_permission(club_id, 'finance_manage'));

-- Rifas y sus participaciones/resultados.
drop policy if exists raffles_manage_manager on public.raffles;
create policy raffles_manage_permission on public.raffles
for all to authenticated
using (public.has_club_permission(club_id, 'raffles_manage'))
with check (public.has_club_permission(club_id, 'raffles_manage'));

drop policy if exists raffle_tickets_select_manager on public.raffle_tickets;
create policy raffle_tickets_select_permission on public.raffle_tickets
for select to authenticated
using (
  public.has_club_permission(club_id, 'raffles_view')
  or buyer_profile_id = auth.uid()
);

drop policy if exists raffle_draws_select_manager on public.raffle_draws;
create policy raffle_draws_select_permission on public.raffle_draws
for select to authenticated
using (public.has_club_permission(club_id, 'raffles_view'));

-- Noticias.
drop policy if exists posts_manage_manager on public.posts;
create policy posts_manage_permission on public.posts
for all to authenticated
using (public.has_club_permission(club_id, 'news_manage'))
with check (public.has_club_permission(club_id, 'news_manage'));

-- Eventos.
drop policy if exists events_manage_manager on public.events;
create policy events_manage_permission on public.events
for all to authenticated
using (public.has_club_permission(club_id, 'events_manage'))
with check (public.has_club_permission(club_id, 'events_manage'));

-- Auditoría: solo los roles de gestión existentes siguen pudiendo consultarla.
drop policy if exists audit_logs_select_manager on public.audit_logs;
create policy audit_logs_select_access_manager on public.audit_logs
for select to authenticated
using (
  club_id is not null
  and public.has_club_permission(club_id, 'access_manage')
);
