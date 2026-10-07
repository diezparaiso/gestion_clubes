-- Borrador solamente: revisar y ejecutar manualmente si se aprueba.
-- Alinea la matriz con ClubRolePermissions y con la decisión de QA:
-- presidente gestiona patrocinadores; entrenador conserva solo lectura.

insert into public.club_role_permissions (role, permission)
values (
  'club_president'::public.club_role,
  'sponsors_manage'::public.club_permission
)
on conflict (role, permission) do nothing;

delete from public.club_role_permissions
where role = 'coach'::public.club_role
  and permission = 'players_manage'::public.club_permission;
