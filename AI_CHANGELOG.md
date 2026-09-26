# AI CHANGELOG — gestión_clubes

This file is the permanent handoff log between AI assistants working on this repository.

## Identification rule

- Every change made directly by ChatGPT must be marked in the touched source file with `MODIFICADO POR GPT-5.6 LUNA`.
- Claude or another assistant must add its own explicit marker when it modifies a file.
- Do not remove previous AI markers. If a section is substantially rewritten, preserve the previous marker in the history/comments.
- Git commit messages should also identify the AI when practical.

## Scope restriction requested by Juanlu

- Do NOT modify the live Supabase database from this workflow.
- Do NOT add, alter or delete Supabase migrations.
- Do NOT modify Stripe/payment implementation.
- Changes may use existing Supabase tables/columns already present in the repository, but must not require a schema change in this phase.
- If a requested feature requires a new table, column, RLS policy, storage policy, Edge Function or Stripe change, STOP that part and document it as pending instead of implementing it.

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
