-- 044_platform_admin_security.sql
-- Helper de autorización para funciones globales de la plataforma.
-- El claim debe estar en app_metadata, que solo puede modificar un entorno de confianza.
create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'platform_admin') = 'true', false);
$$;

revoke all on function public.is_platform_admin() from public, anon;
grant execute on function public.is_platform_admin() to authenticated, service_role;

comment on function public.is_platform_admin() is
  'Devuelve true únicamente cuando el JWT firmado incluye app_metadata.platform_admin=true.';
