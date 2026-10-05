-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): base para gestión de accesos, permisos y cambio obligatorio de contraseña.

alter table public.profiles
  add column if not exists must_change_password boolean not null default false;

do $$ begin
  create type public.club_permission as enum (
    'dashboard_view','members_view','members_manage','teams_view','teams_manage',
    'players_view','players_manage','finance_view','finance_manage',
    'raffles_view','raffles_manage','news_view','news_manage','events_view',
    'events_manage','notifications_view','club_settings_view','club_settings_manage',
    'access_manage'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.club_role_permissions (
  role public.club_role not null,
  permission public.club_permission not null,
  primary key (role, permission)
);

alter table public.club_role_permissions enable row level security;

drop policy if exists club_role_permissions_select_authenticated on public.club_role_permissions;
create policy club_role_permissions_select_authenticated
on public.club_role_permissions
for select to authenticated using (true);

insert into public.club_role_permissions (role, permission)
select role::public.club_role, permission::public.club_permission from (values
('club_president'::public.club_role,'dashboard_view'),('club_president','members_view'),('club_president','members_manage'),('club_president','teams_view'),('club_president','teams_manage'),('club_president','players_view'),('club_president','players_manage'),('club_president','finance_view'),('club_president','finance_manage'),('club_president','raffles_view'),('club_president','raffles_manage'),('club_president','news_view'),('club_president','news_manage'),('club_president','events_view'),('club_president','events_manage'),('club_president','notifications_view'),('club_president','club_settings_view'),('club_president','club_settings_manage'),('club_president','access_manage'),
('club_treasurer','dashboard_view'),('club_treasurer','finance_view'),('club_treasurer','finance_manage'),('club_treasurer','notifications_view'),
('club_secretary','dashboard_view'),('club_secretary','members_view'),('club_secretary','members_manage'),('club_secretary','news_view'),('club_secretary','news_manage'),('club_secretary','events_view'),('club_secretary','events_manage'),('club_secretary','notifications_view'),
('team_manager','dashboard_view'),('team_manager','teams_view'),('team_manager','players_view'),('team_manager','players_manage'),('team_manager','notifications_view'),
('coach','dashboard_view'),('coach','teams_view'),('coach','players_view'),('coach','players_manage'),('coach','notifications_view'),
('staff','dashboard_view'),('staff','notifications_view'),('member','dashboard_view'),('member','members_view'),('member','notifications_view'),
('parent_guardian','dashboard_view'),('parent_guardian','players_view'),('parent_guardian','notifications_view'),
('player','dashboard_view'),('player','players_view'),('player','notifications_view'),('follower','dashboard_view'),('follower','notifications_view')
) as defaults(role, permission) on conflict do nothing;

create or replace function public.has_club_permission(target_club_id uuid, target_permission public.club_permission)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_platform_admin() or exists (
    select 1 from public.club_memberships cm
    join public.club_role_permissions rp on rp.role = cm.role
    where cm.club_id = target_club_id and cm.profile_id = auth.uid()
      and cm.is_active and rp.permission = target_permission
  );
$$;

revoke all on function public.has_club_permission(uuid, public.club_permission) from public;
grant execute on function public.has_club_permission(uuid, public.club_permission) to authenticated;

-- La gestión de accesos queda deliberadamente reservada al presidente.
