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

## 2026-09-26 — GPT-5.6 LUNA

Branch: `feature/gpt-gestion-clubes`

### Modified

- `lib/features/teams/data/repositories/team_repository.dart`
  - Added `updateTeam(...)` using existing `teams.name`, `teams.category` and `teams.season_id` fields.
  - Added `setTeamActive(...)` using existing `teams.is_active`.
  - Uses logical deactivation instead of physical deletion so team history is retained.
  - Added source comments identifying GPT-5.6 LUNA as the modifier.

### Not modified

- `supabase/migrations/*`: untouched.
- Stripe/payment code: untouched.
- Database schema: no changes.

### Pending work

- Team management UI still needs the edit/activate actions wired into `teams_page.dart`.
- Users and roles UI.
- Complete member management.
- Player CRUD and team assignment.
- Guardians.
- Player photos and approval workflow.
- Staff management.
- Permission-aware UI.

## Handoff instruction for Claude

Before changing a file, read this log and the existing AI markers. After changing it, add a concise marker identifying Claude, date, file and purpose. Never overwrite or remove another AI's historical marker.