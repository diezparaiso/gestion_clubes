-- Borrador para revisar; no ejecutar automaticamente.
-- Los resultados E2E mostraron que el presidente no tiene la fila sponsors_manage
-- en club_role_permissions y que coach puede modificar players.
-- El cambio restaura patrocinadores solo al presidente y convierte coach a lectura.

begin;

insert into public.club_role_permissions (role, permission)
values ('club_president', 'sponsors_manage')
on conflict (role, permission) do nothing;

delete from public.club_role_permissions
where role = 'coach'
  and permission = 'players_manage';

commit;
