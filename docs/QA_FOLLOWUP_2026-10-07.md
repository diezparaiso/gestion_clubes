# Seguimiento de QA — 2026-10-07

## Alcance y ejecución

- Consultas remotas de solo lectura con Supabase CLI a `club_role`, `club_role_permissions`, `pg_policies` y `pg_proc`/`pg_get_functiondef` completadas.
- No se ejecutaron migraciones ni los borradores `docs/sql/050_draft.sql`, `docs/sql/051_draft.sql` o `docs/sql/qa_seed.sql`; tampoco se hizo push.
- Los POST a `/rest/v1/notifications` con `Prefer: return=minimal` y `Prefer: return=representation` quedaron **NO EJECUTADOS**: no hay una sesión/JWT de presidente disponible. El runner E2E no conserva credenciales. No se crearon cuentas QA nuevas.

## A) Alta de clubes

`public.create_club` inserta directamente `lower(trim(club_slug))` y no trata la violación de `clubs_slug_key`; la restricción única provoca SQLSTATE `23505` para el segundo intento con el mismo identificador. `AuthController.createClub` mostraba `PostgrestException.message` literalmente y no recargaba los clubes tras el fallo.

El mensaje «No se ha podido crear el club. Inténtalo de nuevo.» procede del `catch (_)`: ocurre ante cualquier error que no entre en los `catch` específicos de `PostgrestException` o `AuthException` (por ejemplo, un error de tipo/parseo al convertir la respuesta o una excepción de transporte). Sin el error original de ese segundo nombre no se puede determinar cuál de esas condiciones ocurrió. Una `PostgrestException` de slug duplicado se mostraba como texto crudo, no con ese mensaje genérico.

## B) Notificaciones y RLS

`NotificationRepository` construía `.insert(...).select(...).single()`: PostgREST solicita representación de la fila (`return=representation`), no `return=minimal`. La política vigente de SELECT solo deja leer notificaciones con una entrega para `auth.uid()`, y el trigger `AFTER INSERT` crea esas entregas. Esto hace plausible la hipótesis de la interacción entre `RETURNING`, RLS y el trigger, pero **no la confirma**: faltan ambos POST comparativos con una sesión de presidente.

El borrador 051 propone `create_notification(...) returns uuid`, `SECURITY DEFINER`, `search_path` fijo, validación de tipos/destinatarios, autorización con `is_club_manager`, ejecución solo por `authenticated` y revocación de INSERT directo (incluidos los permisos por columna). El cliente invoca esa RPC. El borrador no se aplicó.

## C) Matriz de permisos y políticas

El enum remoto tiene diez roles: `club_president`, `club_treasurer`, `club_secretary`, `team_manager`, `coach`, `staff`, `member`, `parent_guardian`, `player` y `follower`. La comparación completa de filas SQL y Dart encontró solo estas diferencias:

| Rol | Diferencia SQL frente a Dart |
|---|---|
| `club_president` | Falta `sponsors_manage` en SQL; Dart lo concede. |
| `coach` | SQL concede `players_manage`; Dart no lo concede. |

Los demás permisos de todos los roles coinciden. En el estado remoto actual, las políticas `ALL` de `players` y `team_players` usan `has_club_permission(..., 'players_manage')`; como el entrenador aún tiene ese permiso en SQL, sí puede escribir en ambas tablas. `teams` usa `teams_manage`, que el entrenador no tiene. Por tanto, **hoy no se cumple** que ninguna política permita al entrenador escribir en las tres tablas. El borrador 050 elimina el permiso que habilita las dos primeras; no se puede afirmar el resultado desplegado hasta que alguien lo aplique y lo verifique.

## D) Funciones SECURITY DEFINER de CAT-DEFINER-REVIEW

Las 14 definiciones remotas consultadas tienen `search_path` fijo. Todas permiten `authenticated` y `service_role`; solo las filas marcadas «sí» permiten `anon`. Las funciones trigger aparecen ejecutables para el rol autenticado en ACL, pero su tipo `trigger` impide invocarlas como RPC normal.

| Función | anon / auth | Guarda observada | Veredicto |
|---|---|---|---|
| `audit_raffle_draw_insert()` | no / sí | Trigger de INSERT; copia los datos del nuevo sorteo al log. | Correcta como trigger acotado. |
| `create_default_financial_account()` | no / sí | Trigger de INSERT en clubes; crea la cuenta inicial para `NEW.id`. | Correcta como trigger acotado. |
| `get_public_club(text)` | sí / sí | Club activo; devuelve solo campos de perfil público. | Correcta, pública por diseño. |
| `get_public_events(text)` | sí / sí | Club activo, evento público y no vencido. | Correcta, pública por diseño. |
| `get_public_posts(text)` | sí / sí | Club activo y publicación publicada. | Correcta, pública por diseño. |
| `get_public_raffle_numbers(text,text)` | sí / sí | Rifa activa; solo números pagados o con reserva vigente. | Observación: no comprueba que el club siga activo. |
| `get_public_sponsors(text)` | sí / sí | Club/contrato activo y sponsor público; omite datos de contacto. | Correcta, pública por diseño. |
| `handle_new_user()` | no / sí | Trigger de `auth.users`; crea/actualiza el perfil con `NEW`. | Correcta como trigger acotado. |
| `has_public_active_raffle(uuid)` | sí / sí | Devuelve solo si existe una rifa activa. | Observación: el predicado no comprueba el estado del club. |
| `is_platform_admin()` | no / sí | Lee `platform_admin` del JWT firmado (`app_metadata`). | Correcta; no confía en un valor enviado por el cliente. |
| `reserve_public_raffle_numbers(...)` | sí / sí | Valida comprador, cantidad/rango, rifa activa y fecha; bloquea la rifa y reserva números. | Pública por diseño; observación: no comprueba el estado del club. |
| `validate_financial_transaction_account()` | no / sí | Trigger; exige que la cuenta pertenezca al club de la transacción. | Correcta como trigger de integridad. |
| `validate_team_player_club_integrity()` | no / sí | Trigger; exige que equipo, jugador y fila pertenezcan al mismo club. | Correcta como trigger de integridad. |
| `validate_team_staff_club_integrity()` | no / sí | Trigger; exige equipo del club y membresía activa del perfil. | Correcta como trigger de integridad. |

Las tres observaciones de rifas dependen de la regla de negocio para clubes suspendidos: una rifa que permanezca `active` puede seguir apareciendo, revelar números reservados o aceptar reservas. Conviene decidir si esas funciones también deben exigir `clubs.status = 'active'`; no se modificaron por estar fuera del alcance.

## QA del seed

`raffle_tickets.purchased_at` existe en la definición de la migración 007. El seed busca rifas con `status = 'active'` y `end_at < now()`, por lo que se corrigió su error a «No ended active QA raffle found». Ahora omite la inserción si ya hay un ticket `qa-test-only` en la rifa QA seleccionada. El archivo sigue sin ejecutarse.
