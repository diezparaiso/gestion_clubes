-- MODIFICADO POR GITHUB COPILOT (2026-10-06): corrige la ACL pública de rifas y revoca el sorteo legado.

-- 007's clubs_select_public_raffle policy queries raffles.club_id/status.
-- 047 intentionally does not grant raffles.club_id to anon, so evaluate this
-- existence test with a narrowly scoped SECURITY DEFINER predicate instead.
create or replace function public.has_public_active_raffle(target_club_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.raffles r
    where r.club_id = target_club_id
      and r.status = 'active'
  );
$$;

revoke all on function public.has_public_active_raffle(uuid)
  from public, anon, authenticated;
grant execute on function public.has_public_active_raffle(uuid)
  to anon, authenticated;

drop policy if exists clubs_select_public_raffle on public.clubs;
create policy clubs_select_public_raffle on public.clubs
for select to anon
using (public.has_public_active_raffle(id));

-- 009 exposes an obsolete SECURITY DEFINER draw RPC to authenticated callers.
-- The Flutter repository uses draw_raffle_random_secure instead; close the
-- legacy entry point so it cannot bypass raffles_manage/date/locking checks.
revoke all on function public.draw_raffle_random(uuid)
  from public, anon, authenticated, service_role;
