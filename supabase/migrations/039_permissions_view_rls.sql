-- MODIFICADO POR GPT-5.6 LUNA (2026-09-27): evita lecturas directas fuera de los permisos *_view.
-- No se ejecuta automáticamente sobre Supabase remoto.

drop policy if exists memberships_select_member on public.memberships;
create policy memberships_select_permission on public.memberships
for select to authenticated
using (public.has_club_permission(club_id, 'members_view'));

drop policy if exists seasons_select_member on public.seasons;
create policy seasons_select_permission on public.seasons
for select to authenticated
using (public.has_club_permission(club_id, 'teams_view'));

drop policy if exists teams_select_member on public.teams;
create policy teams_select_permission on public.teams
for select to authenticated
using (public.has_club_permission(club_id, 'teams_view'));

drop policy if exists players_select_member on public.players;
create policy players_select_permission on public.players
for select to authenticated
using (public.has_club_permission(club_id, 'players_view'));

drop policy if exists team_players_select_member on public.team_players;
create policy team_players_select_permission on public.team_players
for select to authenticated
using (public.has_club_permission(club_id, 'players_view'));

drop policy if exists team_staff_select_member on public.team_staff;
create policy team_staff_select_permission on public.team_staff
for select to authenticated
using (public.has_club_permission(club_id, 'teams_view'));

drop policy if exists raffles_select_member on public.raffles;
create policy raffles_select_permission on public.raffles
for select to authenticated
using (public.has_club_permission(club_id, 'raffles_view'));

drop policy if exists posts_select_member on public.posts;
create policy posts_select_permission on public.posts
for select to authenticated
using (public.has_club_permission(club_id, 'news_view'));

drop policy if exists events_select_member on public.events;
create policy events_select_permission on public.events
for select to authenticated
using (public.has_club_permission(club_id, 'events_view'));

drop policy if exists notifications_select_member on public.notifications;
create policy notifications_select_permission on public.notifications
for select to authenticated
using (public.has_club_permission(club_id, 'notifications_view'));

drop policy if exists club_memberships_select_member on public.club_memberships;
create policy club_memberships_select_own_or_access on public.club_memberships
for select to authenticated
using (
  profile_id = auth.uid()
  or public.has_club_permission(club_id, 'access_manage')
);
