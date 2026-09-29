-- MODIFICADO POR GPT-5.6 LUNA (2026-09-29): cierra la vía de cliente para
-- modificar directamente profiles.must_change_password.
-- El cliente debe usar el RPC tras actualizar la contraseña.
-- No se ejecuta automáticamente sobre Supabase remoto.

create or replace function public.clear_must_change_password()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.profiles
  set must_change_password = false
  where id = auth.uid();

  return found;
end;
$$;

revoke all on function public.clear_must_change_password() from public;
grant execute on function public.clear_must_change_password() to authenticated;

-- El cliente conserva solo las columnas de perfil editables por el usuario.
-- must_change_password queda fuera del privilegio UPDATE de authenticated.
revoke update on public.profiles from authenticated;
grant update (first_name, last_name, phone, date_of_birth, avatar_url)
on public.profiles to authenticated;
