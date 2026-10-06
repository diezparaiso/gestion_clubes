# Verificación de seguridad pendiente

Las migraciones 047 y 048 están aplicadas y `supabase migration list` confirma 001–048 en Local y Remote.

La CLI disponible no pudo ejecutar `docs/sql/security_checks.sql` por Management API: `LegacyDbQueryUnexpectedStatusError`, HTTP 400, SQLSTATE 42809, `"min" is an aggregate function`. No se hicieron intentos alternativos ni SQL de escritura.

## Pasos en Supabase SQL Editor

1. Abre `docs/sql/security_checks.sql` y pega el bloque 0. Debe devolver cero filas para `buyer_profile_id`/`profile_id` incompatibles.
2. Ejecuta por separado los bloques 1–8 del mismo archivo.
3. Confirma que el bloque 1 devuelve, para anon, solo `clubs.id/public_name/slug` y las columnas públicas concedidas de `raffles`.
4. Revisa el bloque 2: no debe aparecer acceso de `anon` ni `PUBLIC` a tablas/columnas privadas.
5. Revisa el bloque 3 junto con RLS; `profiles` debe limitarse a `id`, nombres, `email` y `must_change_password`, y notificaciones a sus campos de lectura.
6. En el bloque 4, todas las tablas listadas deben tener RLS activado; las notificaciones deben usar el filtro de entregas propias.
7. En el bloque 5, inspecciona cada RPC ejecutable por anon: ninguna respuesta debe contener email, teléfono, dirección, fecha de nacimiento, tax_id, buyer_profile_id, tokens ni contact_email.
8. El bloque 6 debe devolver cero funciones `SECURITY DEFINER` sin `search_path` fijo.
9. El bloque 7 debe mostrar `anon_can_execute=false`, `authenticated_can_execute=false`, `service_role_can_execute=true`.
10. El bloque 8 debe devolver `conflicting_owner_rows=0`.

No declares completa la validación hasta revisar los resultados reales de SQL Editor y probar RLS con usuarios de los roles correspondientes en staging.
