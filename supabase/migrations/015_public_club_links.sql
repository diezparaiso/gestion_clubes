drop function if exists public.get_public_club(text);

create or replace function public.get_public_club(target_club_slug text)
returns table (id uuid, public_name text, slug citext, website text, instagram_url text, facebook_url text, youtube_url text)
language sql security definer set search_path = public
as $$
  select c.id, c.public_name, c.slug, c.website, c.instagram_url, c.facebook_url, c.youtube_url
  from public.clubs c
  where c.slug::text = lower(target_club_slug) and c.status = 'active';
$$;

revoke all on function public.get_public_club(text) from public;
grant execute on function public.get_public_club(text) to anon, authenticated;
