-- Borrador manual; NO ejecutar automáticamente ni en producción.
-- Limpia únicamente cuentas y contenido QA cuyo nombre contiene el timestamp
-- de las corridas del 07-10-2026. Revisar los resultados de preflight antes de
-- ejecutar en una sesión administrativa controlada.
--
-- La tabla audit_logs es inmutable por trigger. La rutina deshabilita solo ese
-- trigger dentro de esta transacción para retirar los logs asociados a estos
-- fixtures; cualquier error revierte también el estado del trigger.

begin;

-- Preflight: revisar exactamente qué filas quedarían afectadas.
select id, email
from auth.users
where email like 'qa-20261007-%';

select id, slug, public_name, legal_name
from public.clubs
where slug::text like 'qa-%20261007-%'
   or public_name like 'qa-%20261007-%'
   or legal_name like 'qa-%20261007-%';

select id, club_id, name
from public.sponsors
where name like 'qa-%20261007-%';

select id, club_id, title, body
from public.notifications
where title like 'qa-%20261007-%'
   or body like 'qa-%20261007-%';

-- Impide eliminar perfiles QA que aún estén vinculados a datos de clubes ajenos
-- a los clubes QA identificados arriba.
do $$
begin
  if exists (
    select 1
    from public.profiles p
    join auth.users u on u.id = p.id
    where u.email like 'qa-20261007-%'
      and (
        exists (
          select 1 from public.memberships m
          where m.profile_id = p.id
            and not exists (
              select 1 from public.clubs c
              where c.id = m.club_id
                and (
                  c.slug::text like 'qa-%20261007-%'
                  or c.public_name like 'qa-%20261007-%'
                  or c.legal_name like 'qa-%20261007-%'
                )
            )
        )
        or exists (
          select 1 from public.players pl
          where pl.profile_id = p.id
            and not exists (
              select 1 from public.clubs c
              where c.id = pl.club_id
                and (
                  c.slug::text like 'qa-%20261007-%'
                  or c.public_name like 'qa-%20261007-%'
                  or c.legal_name like 'qa-%20261007-%'
                )
            )
        )
        or exists (
          select 1 from public.team_staff ts
          where ts.profile_id = p.id
            and not exists (
              select 1 from public.clubs c
              where c.id = ts.club_id
                and (
                  c.slug::text like 'qa-%20261007-%'
                  or c.public_name like 'qa-%20261007-%'
                  or c.legal_name like 'qa-%20261007-%'
                )
            )
        )
      )
  ) then
    raise exception 'Hay usuarios QA vinculados a clubes ajenos al conjunto QA; revisar manualmente.';
  end if;
end
$$;

alter table public.audit_logs disable trigger audit_logs_immutable_update;

delete from public.audit_logs al
where al.club_id in (
    select c.id
    from public.clubs c
    where c.slug::text like 'qa-%20261007-%'
       or c.public_name like 'qa-%20261007-%'
       or c.legal_name like 'qa-%20261007-%'
  )
  or al.actor_profile_id in (
    select u.id from auth.users u
    where u.email like 'qa-20261007-%'
  )
  or al.entity_id in (
    select s.id from public.sponsors s
    where s.name like 'qa-%20261007-%'
  );

alter table public.audit_logs enable trigger audit_logs_immutable_update;

delete from public.notifications
where title like 'qa-%20261007-%'
   or body like 'qa-%20261007-%';

delete from public.sponsors
where name like 'qa-%20261007-%';

-- Las FKs en cascada eliminan el contenido, membresías y dependencias de estos
-- clubes QA (incluidos sponsors y notifications que no se borraron arriba).
delete from public.clubs
where slug::text like 'qa-%20261007-%'
   or public_name like 'qa-%20261007-%'
   or legal_name like 'qa-%20261007-%';

-- auth.users -> profiles; el perfil elimina las membresías y entregas restantes.
delete from auth.users
where email like 'qa-20261007-%';

-- Revisión de registros restantes antes de confirmar manualmente.
select 'qa_users_remaining' as check_name, count(*) as remaining
from auth.users
where email like 'qa-20261007-%'
union all
select 'qa_clubs_remaining', count(*)
from public.clubs
where slug::text like 'qa-%20261007-%'
   or public_name like 'qa-%20261007-%'
   or legal_name like 'qa-%20261007-%'
union all
select 'qa_sponsors_remaining', count(*)
from public.sponsors
where name like 'qa-%20261007-%'
union all
select 'qa_notifications_remaining', count(*)
from public.notifications
where title like 'qa-%20261007-%'
   or body like 'qa-%20261007-%';

-- Confirmar solo después de revisar los resultados; COMMIT explícito requerido.
-- COMMIT;
-- ROLLBACK;
