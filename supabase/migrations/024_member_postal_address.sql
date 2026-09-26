-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Añade domicilio postal al expediente del socio.
-- La dirección pertenece a la relación socio-club para permitir datos distintos por club.

alter table public.memberships
  add column if not exists address text,
  add column if not exists postal_code text,
  add column if not exists city text,
  add column if not exists province text,
  add column if not exists country text not null default 'ES';
