create or replace function public.get_public_club(target_club_slug text)
returns table (id uuid, public_name text, slug citext)
language sql security definer set search_path = public
as $$
  select c.id, c.public_name, c.slug
  from public.clubs c
  where c.slug::text = lower(target_club_slug) and c.status = 'active';
$$;

revoke all on function public.get_public_club(text) from public;
grant execute on function public.get_public_club(text) to anon, authenticated;