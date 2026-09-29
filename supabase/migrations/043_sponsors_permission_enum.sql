-- MODIFICADO POR GPT-5.6 LUNA (2026-09-29): incorpora sponsors_manage al catálogo SQL de permisos.
-- No se ejecuta automáticamente sobre Supabase remoto.
--
-- Se separa del seed/policies de patrocinadores porque ALTER TYPE ... ADD VALUE
-- debe quedar en su propia migración para evitar usar el nuevo enum value
-- antes de que la transacción de alteración haya finalizado.

alter type public.club_permission add value if not exists 'sponsors_manage';
