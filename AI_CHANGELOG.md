# AI CHANGELOG — gestión_clubes

This file is the permanent handoff log between AI assistants working on this repository.

## Identification rule

- Every change made directly by ChatGPT must be marked in the touched source file with `MODIFICADO POR GPT-5.6 LUNA`.
- Claude or another assistant must add its own explicit marker when it modifies a file.
- Do not remove previous AI markers. If a section is substantially rewritten, preserve the previous marker in the history/comments.
- Git commit messages should also identify the AI when practical.

## Working rules requested by Juanlu

- Do NOT modify the live Supabase database from this workflow. Repository migrations may be created or updated, but they are **not executed against the live Supabase project** from this workflow.
- Supabase migrations are part of the repository and may be added when required by the planned application architecture, integrity, RLS or data model. Their remote application remains a separate deployment step.
- Do NOT modify the Stripe/payment implementation in gestion_clubes unless that integration is explicitly scheduled. The separate payments project remains independent until integration is planned.
- If a requested feature requires a schema, RLS, storage policy, Edge Function or payment change, document the change and keep live deployment separate from code changes.

### 2026-09-26 — GPT-5.6 LUNA — documentación de reglas de trabajo
- Se corrige la antigua restricción documental que prohibía crear o modificar migraciones, porque el repositorio ya contiene migraciones 020–024 creadas durante este desarrollo.
- Se mantiene la separación entre cambios de código/migraciones del repositorio y la aplicación de esos cambios sobre el Supabase remoto.
- Stripe/pagos siguen fuera de gestion_clubes hasta que se programe explícitamente su integración.

## 2026-09-26 — GPT-5.6 LUNA — continued implementation

- Previous work recorded above is preserved.
- `supabase/migrations/021_raffle_ticket_integrity.sql`
  - Added validation for raffle ticket range and club ownership.
- `supabase/migrations/022_raffle_number_range_consistency.sql`
  - Corrected an existing off-by-one inconsistency: public reservations previously accepted 0..total_numbers-1 while the application and new integrity trigger use 1..total_numbers.
  - Tightened the database check to require ticket numbers >= 1.
  - Replaced the public reservation function so valid numbers are 1..total_numbers.
- Important: these migration files are repository changes only and have not been executed against live Supabase.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — sponsor demo-mode robustness
- `lib/features/sponsors/data/repositories/sponsor_repository.dart`
  - Made the Supabase client nullable and only accesses `Supabase.instance.client` when Supabase is configured.
  - Prevents the demo/offline mode from requiring an initialized Supabase client.
- No database schema change.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — event date/time integrity
- `lib/features/events/presentation/pages/events_page.dart`
  - Replaced the fixed `now + 7 days` event timestamp with selectable start/end date and time.
  - Prevents saving an event whose end is not after its start.
- No database schema change.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — notification target integrity
- `supabase/migrations/023_notification_target_integrity.sql`
  - Adds the missing `members` target handling.
  - Uses the actual schema roles (`club_president`, `club_secretary`) for managers.
  - Restricts recipients to active memberships/staff.
  - Keeps delivery deduplication via the existing unique constraint.
- Repository migration only; live Supabase has not been executed from this workflow.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — news CRUD completion
- `lib/features/news/data/repositories/post_repository.dart`: añade actualización y borrado, valida título/contenido y mantiene coherencia de `published_at` según estado.
- `lib/features/news/presentation/pages/posts_page.dart`: añade edición, borrado confirmado y soporte visual para borradas/archivadas.
- Sin cambios de esquema; live Supabase no ejecutado desde este workflow.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — raffle UI consistency
- `lib/features/raffles/presentation/pages/public_raffle_page.dart`: corrige la cuadrícula pública para ofrecer exactamente los números 1..total_numbers, coherente con la validación de Supabase.
- `lib/features/raffles/presentation/pages/raffles_page.dart`: valida que precio y cantidad de números sean mayores que cero antes del alta.
- Sin cambios de esquema en este bloque. Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — player club_id integrity
- `lib/features/players/data/repositories/player_repository.dart`: corrige el alta para informar `club_id` tanto en `players` como en `team_players`, y limita la reutilización de un jugador al club activo.
- `lib/features/players/presentation/pages/team_players_page.dart`: pasa el `club_id` de la sesión al repositorio.
- Se trata de una corrección de datos obligatorios ya existentes; no requiere cambios de esquema.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — raffle creation invariants
- `lib/features/raffles/data/repositories/raffle_repository.dart`: valida título, precio, rango de números y fecha de finalización antes de crear una rifa.
- `lib/features/raffles/presentation/pages/raffles_page.dart`: muestra los errores de validación al usuario.
- Sin cambios de esquema. Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — public content polish
- lib/features/events/presentation/pages/public_events_page.dart: muestra fecha y hora de inicio y fin usando los datos reales del evento.
- lib/features/news/presentation/pages/public_posts_page.dart: muestra image_url cuando existe, manteniendo el contenido público basado en el RPC existente.
- lib/features/raffles/data/repositories/raffle_repository.dart: corrige una inserción accidental de validaciones de creación dentro de getPublicRaffle; las validaciones quedan únicamente en createRaffle.
- Sin cambios de esquema en este bloque. Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — player assignment security
- lib/features/players/data/repositories/player_repository.dart: valida antes del alta que el equipo indicado pertenece al club activo; evita asignaciones cruzadas entre clubes desde el cliente.
- No requiere cambio de esquema. Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — raffle activation flow
- `lib/features/raffles/data/repositories/raffle_repository.dart`: las nuevas rifas pasan a `active` al crearse, porque la interfaz actual no ofrece una acción separada para activarlas y el RPC público solo expone rifas activas.
- Usa únicamente la columna `status` existente; no requiere cambio de esquema.
- Stripe/payment implementation remains untouched.


### 2026-09-26 — GPT-5.6 LUNA — simple public raffle sharing
- `lib/features/raffles/data/repositories/raffle_repository.dart`: carga el `slug` público y el `club_slug` existentes para poder construir el enlace público de cada rifa desde la gestión.
- `lib/features/raffles/presentation/pages/raffle_detail_page.dart`: añade una acción sencilla para copiar el enlace público y pegarlo después en WhatsApp u otro canal.
- No se añade un sistema de WhatsApp ni nuevas tablas/endpoints.
- El pago real de la participación sigue separado del flujo actual; no se modifica Stripe/payment en este bloque.


### 2026-09-26 — GPT-5.6 LUNA — public club link sharing
- lib/features/clubs/presentation/pages/club_settings_page.dart: añadido botón simple para copiar el enlace público del club y corregida la anotación @override duplicada existente.
- No se ha creado integración directa con WhatsApp.
- El enlace queda preparado para compartir externamente.
- Pagos/Stripe no modificados.
- La función backend draw_raffle_random fue verificada en 009_raffle_draws.sql; no se modifica en este bloque.


### 2026-09-26 — GPT-5.6 LUNA — public content link sharing
- lib/features/events/presentation/pages/events_page.dart: botón simple para copiar el enlace público de la agenda del club.
- lib/features/news/presentation/pages/posts_page.dart: botón simple para copiar el enlace público de noticias.
- Se reutilizan las rutas públicas existentes; no se crea integración con WhatsApp ni backend adicional.
- Pagos/Stripe no modificados.

### 2026-09-26 — GPT-5.6 LUNA — repair after branch update
- Repaired the public events page string literal that caused the Dart parser errors.
- Repaired the post repository validation exception so it is valid with the current SDK.
- Public raffle/router analyzer errors were reviewed; the reported router error is a cascade from the public raffle page analyzer failure, while the fetched branch source is structurally valid. No payment/Stripe changes.


### 2026-09-26 — GPT-5.6 LUNA — repair public raffle imports
- Fixed a malformed literal \
 sequence at the beginning of `public_raffle_page.dart` that commented out the Flutter imports and caused the large analyzer cascade, including the router type error.
- Fixed the non-const `AuthException` invocation in `post_repository.dart`.
- No payment/Stripe changes and no live Supabase execution.


### 2026-09-26 — GPT-5.6 LUNA — final analyzer error repair
- Removed an invalid `const StateError` invocation in `post_repository.dart`.
- The remaining analyzer messages are informational/warnings only and are not blocking errors.

### 2026-09-26 — GPT-5.6 LUNA — finance balance integrity
- `lib/features/finance/presentation/pages/finance_page.dart`: el saldo ya no usa un valor fijo en la interfaz; toma el saldo inicial mediante `getOpeningBalance` del repositorio y suma/resta los movimientos actuales.
- El alta de movimientos rechaza importes cero o negativos antes de guardar.
- Sin cambios de esquema. Stripe/payment implementation remains untouched.

### 2026-09-26 — GPT-5.6 LUNA — staff assignment integrity
- team_staff_repository.dart valida que el equipo pertenece al club activo antes de asignar personal.
- Evita asignaciones cruzadas entre clubes sin cambiar el esquema de Supabase.
- Stripe/payment implementation remains untouched.

### 2026-09-26 — GPT-5.6 LUNA — team and player integrity
- team_repository.dart valida que la temporada pertenece al club activo al crear o editar un equipo.
- player_repository.dart verifica la existencia del equipo antes de editar una asignación de jugador.
- Sin cambios de esquema. Stripe/payment implementation remains untouched.

### 2026-09-26 — GPT-5.6 LUNA — team form validation
- team_repository.dart valida nombres de temporada/equipo y categoría antes de guardar.
- La edición de equipos comprueba la pertenencia de la temporada al club activo.
- Stripe/payment implementation remains untouched.

### 2026-09-26 — GPT-5.6 LUNA — analyzer cleanup
- sponsor_repository.dart elimina aserciones `!` redundantes tras comprobar el cliente Supabase.
- team_staff_repository.dart y post_repository.dart usan interpolación de cadenas donde correspondía.
- Cambios únicamente de código Dart; sin cambios de esquema ni pagos.

### 2026-09-26 — GPT-5.6 LUNA — analyzer lint cleanup continued
- Eliminados los avisos `use_build_context_synchronously` de copia de enlaces públicos en club y rifas.
- Corregido el formato de fechas de socios mediante interpolación.
- Sin cambios de esquema ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — integridad de asignaciones de equipo
- Endurecida la edición de jugadores y personal: ahora se verifica que el equipo pertenece al club activo antes de modificar la asignación.
- La pantalla de edición obtiene el `clubId` de la sesión antes de guardar.
- Sin cambios de esquema Supabase ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — gestión completa de roles de miembros
- Añadidos `parent_guardian` y `follower` al selector de invitación, ya soportados por el enum `club_role` y por el selector de cambio de rol.
- Sin cambios de esquema ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — validación financiera adicional
- Reforzada la validación del repositorio de tesorería: club activo obligatorio, descripción no vacía e importe finito y mayor que cero.
- El alta Supabase reutiliza la descripción normalizada y mantiene la selección de cuenta financiera activa filtrada por `club_id`.
- Sin cambios de esquema ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — validación de eventos
- El repositorio de eventos valida club activo, título y descripción obligatorios y que `end_at` sea posterior a `start_at` antes del alta.
- Normaliza título, descripción y ubicación antes de persistir.
- Sin cambios de esquema ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — validación de socios
- El alta y edición de socios valida club activo y número de socio positivo.
- El alta valida nombre, apellidos y email; la edición valida que renovación y baja no sean anteriores al alta.
- Sin cambios de esquema ni de pagos.

### 2026-09-26 — GPT-5.6 LUNA — domicilio postal de socios
- Se confirma que la versión anterior no permitía introducir dirección postal del socio.
- Añadidos a `memberships`: dirección, código postal, localidad, provincia y país.
- El alta y edición de socios ya permiten introducir y guardar estos datos.
- Añadida migración `024_member_postal_address.sql`; queda pendiente de aplicar en el Supabase remoto.

### 2026-09-26 — GPT-5.6 LUNA — integridad de miembros del club
- El repositorio de miembros valida club activo, email y roles antes de llamar a Supabase.
- Se normalizan los emails a minúsculas.
- Se evita acceder al cliente Supabase cuando la aplicación está en modo demo.
- No se modifica el esquema ni el sistema de pagos en este bloque.

### 2026-09-26 — GPT-5.6 LUNA — validación de reservas públicas de rifas
- El cliente valida enlace, cantidad de números, duplicados, números positivos, nombre y email antes del RPC.
- Normaliza slug, nombre, email y teléfono antes de reservar.
- No se modifica el sistema de pagos.

### 2026-09-26 — GPT-5.6 LUNA — endurecimiento de eventos y noticias
- Los repositorios validan club activo y slug público antes de consultar datos.
- El alta de noticias valida también el club antes de persistir.
- Se endurece la acción de copiar el enlace público de agenda frente a cambios de contexto asíncronos.
- Sin cambios de esquema ni de pagos en este bloque.

### 2026-09-26 — GPT-5.6 LUNA — endurecimiento de miembros del club
- Las consultas de miembros validan club_id y el modo Supabase sin cliente disponible.
- Los diálogos de cambio de rol e invitación no ejecutan setState si el diálogo ya fue desmontado durante una operación asíncrona.
- Sin cambios de esquema ni de pagos en este bloque.

### 2026-09-26 — GPT-5.6 LUNA — endurecimiento de rifas y tesorería
- Se reparó el repositorio de rifas, que había quedado con contenido duplicado/incompleto durante el bloque anterior.
- Las participaciones y el sorteo pasan a validar el club activo antes de operar sobre la rifa.
- Se normalizan y validan los datos de reserva pública y se corrige la validación de email.
- Tesorería valida categorías permitidas, normaliza descripciones y protege el diálogo frente a desmontaje asíncrono.
- Sin cambios de pagos/Stripe en este bloque.

### 2026-09-26 — GPT-5.6 LUNA — cierre del flujo de rifas
- `raffle_detail_page.dart`: evita ejecutar el sorteo sin club activo.
- `raffles_page.dart`: permite elegir fecha y hora reales de finalización y protege el diálogo frente a operaciones asíncronas tras desmontaje.
- La rifa deja de depender de una fecha fija de 30 días.
- Sin cambios de Stripe/pagos.

### 2026-09-26 — GPT-5.6 LUNA — integridad del presidente activo
- Añadida `supabase/migrations/025_revoke_active_president_integrity.sql`.
- `revoke_member_access` ahora cuenta únicamente presidentes activos y bloquea la revocación del único presidente activo.
- La migración queda en el repositorio y pendiente de aplicación en Supabase remoto.

### 2026-09-26 — GPT-5.6 LUNA — integridad financiera de base de datos
- Añadida `supabase/migrations/026_financial_transaction_account_integrity.sql`.
- Las transacciones financieras ahora validan en base de datos que `account_id` pertenece al mismo `club_id`.
- La migración queda en el repositorio y pendiente de aplicación en Supabase remoto.
- Sin cambios de Stripe/pagos.

### 2026-09-26 — GPT-5.6 LUNA — integridad de equipos y personal
- Añadida `027_team_player_club_integrity.sql`: equipo, jugador y `club_id` deben pertenecer al mismo club.
- Añadida `028_team_staff_club_integrity.sql`: equipo, personal y `club_id` deben pertenecer al mismo club y el perfil debe tener membresía activa.
- Las migraciones quedan pendientes de aplicación en Supabase remoto.

### 2026-09-26 — GPT-5.6 LUNA — cierre de integridad, notificaciones, tests y PWA
- Patrocinadores: validación de club, fechas e importe en repositorio y migración `029_sponsor_integrity.sql`.
- Notificaciones: repositorio seguro en modo demo y lectura restringida al usuario autenticado mediante `030_notification_read_integrity.sql`.
- Tests: añadido `test/data_integrity_test.dart` con cobertura de validaciones financieras, rifas, fechas y patrocinadores.
- PWA/producción: actualizados `web/index.html` y `web/manifest.json` con identidad, descripción, viewport y theme-color de producción.
- No se ejecuta ninguna migración sobre Supabase remoto desde este flujo.


### 2026-09-26 — GPT-5.6 LUNA — dashboard actions and real metrics
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`: las acciones rápidas ya navegan a Socios, Tesorería y Rifas en lugar de ejecutar botones sin acción.
- El tercer indicador del dashboard deja de mostrar datos ficticios de rifas y usa el número real de equipos disponible en `dashboardStatsProvider`.
- Se añade el marcador `MODIFICADO POR GPT-5.6 LUNA` al archivo tocado.
- No se modifica Payments, Supabase ni el esquema de base de datos.


### 2026-09-26 — GPT-5.6 LUNA — búsqueda y filtro de equipos
- `lib/features/teams/presentation/pages/teams_page.dart`: añadido buscador local por nombre, categoría o temporada.
- Añadido filtro para mostrar u ocultar equipos inactivos.
- La búsqueda no modifica Supabase ni el esquema de datos; filtra únicamente los equipos ya cargados.
- Se mantiene el estado de edición/activación existente.


### 2026-09-26 — GPT-5.6 LUNA — filtros avanzados de socios
- `lib/features/members/presentation/pages/members_page.dart`: añadido filtrado local por estado y tipo de socio, combinado con la búsqueda existente por nombre, email y número.
- No se realizan consultas adicionales ni cambios de esquema; se filtran los datos ya cargados para el club autenticado.


### 2026-09-26 — GPT-5.6 LUNA — filtros de tesorería
- `lib/features/finance/presentation/pages/finance_page.dart`: añadidos búsqueda local por descripción/categoría y filtro por ingresos/gastos.
- El saldo inicial y los datos financieros siguen procediendo del repositorio; los filtros solo afectan al listado y sus métricas visibles.
- Sin cambios de esquema, RLS ni Payments.

### 2026-09-26 — GPT-5.6 LUNA — corrección de métricas con filtros de tesorería
- Las métricas de saldo, ingresos y gastos mantienen el cálculo sobre todos los movimientos del club.
- Los filtros solo afectan al listado visible, evitando presentar un saldo global incorrecto al buscar o filtrar.

### 2026-09-26 — GPT-5.6 LUNA — filtro de categoría en tesorería
- Se completa el filtro de tesorería con selección de categoría.
- Las categorías visibles reutilizan las categorías ya permitidas por el formulario financiero.
- Sin cambios de esquema, RLS ni Payments.

### 2026-09-26 — GPT-5.6 LUNA — búsqueda y filtro de notificaciones
- `lib/features/notifications/presentation/pages/notifications_page.dart`: añadido buscador local por título/cuerpo y filtro para mostrar solo no leídas.
- Las acciones de marcar como leída y marcar todas siguen usando el repositorio existente.
- Sin cambios de esquema, RLS ni Payments.
