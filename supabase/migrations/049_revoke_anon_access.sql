-- 049_revoke_anon_access.sql
-- Mínimo privilegio para el rol anónimo: sin acceso directo a tablas salvo las columnas
-- públicas de clubs y raffles, y sin EXECUTE en funciones salvo las RPC públicas.
-- Verificado antes de aplicar: ninguna política de anon usa funciones auxiliares de
-- permisos, y las únicas políticas de anon son clubs_select_public_raffle y raffles_select_public.

-- 1) Tablas y vistas
do $$
declare
  t record;
begin
  for t in
    select c.relname
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r', 'v', 'm', 'p')
  loop
    execute format('revoke all on table public.%I from anon', t.relname);
  end loop;
end;
$$;

grant select (id, public_name, slug) on table public.clubs to anon;
grant select (
  id, slug, title, description, image_url, ticket_price, total_numbers, end_at,
  status, raffle_type, winning_number, monthly_day, subscription_enabled
) on table public.raffles to anon;

-- 2) Funciones: solo se tocan las que anon puede ejecutar hoy, excepto las RPC públicas
--    y las de extensiones (citext). Lo que 047 ya había cerrado no se reabre.
do $$
declare
  f record;
  v_authenticated boolean;
  v_service boolean;
begin
  for f in
    select p.oid,
           format('%I.%I(%s)', n.nspname, p.proname, pg_get_function_identity_arguments(p.oid)) as sig,
           (p.prorettype = 'pg_catalog.trigger'::regtype) as is_trigger
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and has_function_privilege('anon', p.oid, 'EXECUTE')
      and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')
      and p.proname not in (
        'get_public_club', 'get_public_events', 'get_public_posts',
        'get_public_raffle_numbers', 'get_public_sponsors',
        'reserve_public_raffle_numbers', 'has_public_active_raffle'
      )
  loop
    v_authenticated := has_function_privilege('authenticated', f.oid, 'EXECUTE');
    v_service := has_function_privilege('service_role', f.oid, 'EXECUTE');

    execute format('revoke execute on function %s from public, anon', f.sig);

    -- Quitar PUBLIC también quita lo heredado: se restaura a quien lo tenía.
    if not f.is_trigger then
      if v_authenticated then
        execute format('grant execute on function %s to authenticated', f.sig);
      end if;
      if v_service then
        execute format('grant execute on function %s to service_role', f.sig);
      end if;
    end if;
  end loop;
end;
$$;

-- 3) Funciones y tablas futuras creadas por esta función de migración: sin acceso por defecto.
--    Cada migración nueva debe conceder explícitamente lo que haga falta.
alter default privileges for role postgres revoke execute on functions from public, anon;
alter default privileges for role postgres in schema public revoke all on tables from anon;