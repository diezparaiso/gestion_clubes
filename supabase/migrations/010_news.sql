do $$
begin
  create type public.post_status as enum ('draft', 'published', 'archived');
exception
  when duplicate_object then null;
end;
$$;

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  body text not null check (length(trim(body)) > 0),
  image_url text,
  author_id uuid not null references public.profiles(id),
  status public.post_status not null default 'draft',
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check ((status = 'published' and published_at is not null) or status <> 'published')
);

create index posts_club_status_idx on public.posts (club_id, status, published_at desc);
create trigger posts_set_updated_at before update on public.posts for each row execute function public.set_updated_at();
alter table public.posts enable row level security;
create policy posts_select_member on public.posts for select to authenticated using (public.is_club_member(club_id));
create policy posts_manage_manager on public.posts for all to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));

create or replace function public.get_public_posts(target_club_slug text)
returns table (id uuid, title text, body text, image_url text, status public.post_status, published_at timestamptz, created_at timestamptz)
language sql security definer set search_path = public
as $$
  select p.id, p.title, p.body, p.image_url, p.status, p.published_at, p.created_at
  from public.posts p join public.clubs c on c.id = p.club_id
  where c.slug::text = lower(target_club_slug) and c.status = 'active' and p.status = 'published'
  order by p.published_at desc;
$$;

revoke all on function public.get_public_posts(text) from public;
grant execute on function public.get_public_posts(text) to anon, authenticated;