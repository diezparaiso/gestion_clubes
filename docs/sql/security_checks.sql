-- Comprobaciones de solo lectura para Supabase SQL Editor. Ejecuta primero el
-- precheck 0 antes de 047 y las comprobaciones restantes después de aplicarla.
-- No contiene cambios de esquema ni escrituras.

-- 0. PRECHECK before applying 047: ownership conflicts in raffle tickets.
-- Correct result before migration: zero rows. If any row is returned, stop and
-- reconcile it manually before applying 047; the migration intentionally aborts
-- on conflicting non-NULL owner IDs and never chooses one automatically.
select id, raffle_id, buyer_profile_id, profile_id
from public.raffle_tickets
where buyer_profile_id is not null
  and profile_id is not null
  and buyer_profile_id <> profile_id;

-- 1. Columnas que anon puede leer efectivamente, incluyendo grants heredados de PUBLIC.
-- Correcto después de 047: solo las columnas de identidad pública de clubs y
-- las columnas públicas de rifas que consulta la página pública de rifa.
with target_tables(table_name) as (
  values
    ('clubs'), ('profiles'), ('club_memberships'), ('notifications'),
    ('notification_deliveries'), ('user_devices'), ('memberships'), ('raffles'),
    ('sponsors'), ('raffle_tickets'), ('audit_logs')
)
select c.table_name, c.column_name
from information_schema.columns c
join target_tables t on t.table_name = c.table_name
where c.table_schema = 'public'
  and has_column_privilege(
    'anon', format('public.%I', c.table_name), c.column_name, 'SELECT'
  )
order by c.table_name, c.ordinal_position;

-- 2. Explicit information_schema grants for anon, PUBLIC and authenticated.
-- Correct after 047: anon has only the three public clubs columns; PUBLIC has none
-- on these tables. Review authenticated results against the RLS policies below.
select grantee, table_name, column_name, privilege_type
from information_schema.column_privileges
where table_schema = 'public'
  and table_name in (
    'clubs', 'profiles', 'club_memberships', 'notifications',
    'notification_deliveries', 'user_devices', 'memberships', 'raffles',
    'sponsors', 'raffle_tickets', 'audit_logs'
  )
  and grantee in ('anon', 'PUBLIC', 'authenticated')
order by grantee, table_name, column_name, privilege_type;

-- 3. Effective authenticated column SELECT privileges.
-- Correct after 047: profiles is limited to id/name/email/must_change_password;
-- notification tables expose only fields needed by the inbox. Other results must
-- be constrained by the matching row-level policies, not treated as public data.
with target_tables(table_name) as (
  values
    ('clubs'), ('profiles'), ('club_memberships'), ('notifications'),
    ('notification_deliveries'), ('user_devices'), ('memberships'), ('raffles'),
    ('sponsors'), ('raffle_tickets'), ('audit_logs')
)
select c.table_name, c.column_name
from information_schema.columns c
join target_tables t on t.table_name = c.table_name
where c.table_schema = 'public'
  and has_column_privilege(
    'authenticated', format('public.%I', c.table_name), c.column_name, 'SELECT'
  )
order by c.table_name, c.ordinal_position;

-- 4. RLS enablement and policies for the audited tables.
-- Correct after 047: every listed table has RLS enabled; notifications has a
-- recipient-delivery SELECT policy, and notification_deliveries has own-row SELECT.
select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'clubs', 'profiles', 'club_memberships', 'notifications',
    'notification_deliveries', 'user_devices', 'memberships', 'raffles',
    'sponsors', 'raffle_tickets', 'audit_logs'
  )
order by c.relname;

select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in (
    'clubs', 'profiles', 'club_memberships', 'notifications',
    'notification_deliveries', 'user_devices', 'memberships', 'raffles',
    'sponsors', 'raffle_tickets', 'audit_logs'
  )
order by tablename, policyname;

-- 5. Publicly executable RPC signatures, result types and definitions.
-- Correct after 047: returned columns contain no email, phone, address, date_of_birth,
-- tax_id, buyer_profile_id, device token or contact_email. Inspect JSON/array results
-- in the displayed definitions as well as the result type.
select p.oid::regprocedure as function_name,
       pg_get_function_result(p.oid) as result_type,
       (pg_get_function_result(p.oid) ~* '(email|phone|address|date_of_birth|tax_id|buyer_profile_id|token|contact_email)')
         as forbidden_name_in_result,
       pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and has_function_privilege('anon', p.oid, 'EXECUTE')
order by p.oid::regprocedure::text;

-- 6. SECURITY DEFINER functions without a function-level search_path setting.
-- Correct result: zero rows. Any returned function must be fixed before release.
select p.oid::regprocedure as function_name,
       p.proconfig,
       pg_get_functiondef(p.oid) as definition
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.prosecdef
  and not exists (
    select 1
    from unnest(coalesce(p.proconfig, array[]::text[])) setting
    where setting like 'search_path=%'
  )
order by p.oid::regprocedure::text;

-- 7. Verify payment RPC execute grants.
-- Correct: anon=false, authenticated=false, service_role=true.
select has_function_privilege(
         'anon', 'public.record_raffle_payment(uuid,uuid,text)', 'EXECUTE'
       ) as anon_can_execute,
       has_function_privilege(
         'authenticated', 'public.record_raffle_payment(uuid,uuid,text)', 'EXECUTE'
       ) as authenticated_can_execute,
       has_function_privilege(
         'service_role', 'public.record_raffle_payment(uuid,uuid,text)', 'EXECUTE'
       ) as service_role_can_execute;

-- 8. Verify ticket owner columns are reconciled.
-- Correct: conflicting_owner_rows = 0. Rows with both IDs null are unclaimed reservations.
select count(*) as conflicting_owner_rows
from public.raffle_tickets
where buyer_profile_id is not null
  and profile_id is not null
  and buyer_profile_id <> profile_id;
