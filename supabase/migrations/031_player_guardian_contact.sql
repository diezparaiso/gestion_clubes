-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Datos de contacto de jugadores y progenitor/responsable.
-- No ejecutar automáticamente sobre Supabase remoto desde este flujo.

alter table public.players
  add column if not exists phone text,
  add column if not exists guardian_name text,
  add column if not exists guardian_phone text,
  add column if not exists guardian_email text,
  add column if not exists guardian_relationship text;

alter table public.players
  add constraint players_phone_length_chk
    check (phone is null or length(trim(phone)) between 3 and 30);

alter table public.players
  add constraint players_guardian_phone_length_chk
    check (guardian_phone is null or length(trim(guardian_phone)) between 3 and 30);

alter table public.players
  add constraint players_guardian_email_format_chk
    check (guardian_email is null or guardian_email = '' or position('@' in guardian_email) > 1);

alter table public.players
  add constraint players_guardian_name_required_with_phone_chk
    check (guardian_phone is null or nullif(trim(guardian_name), '') is not null);
