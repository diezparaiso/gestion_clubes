do $$
begin
  create type public.event_type as enum ('match', 'tournament', 'meeting', 'event', 'fundraiser', 'other');
exception
  when duplicate_object then null;
end;
$$;

do $$
begin
  create type public.visibility as enum ('public', 'club_only', 'private');
exception
  when duplicate_object then null;
end;
$$;

create table public.events (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  description text not null default '',
  location text,
  start_at timestamptz not null,
  end_at timestamptz not null,
  image_url text,
  type public.event_type not null default 'event',
  visibility public.visibility not null default 'club_only',
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (end_at >= start_at)
);

create index events_club_dates_idx on public.events (club_id, start_at, end_at);
create trigger events_set_updated_at before update on public.events for each row execute function public.set_updated_at();
alter table public.events enable row level security;
create policy events_select_member on public.events for select to authenticated using (public.is_club_member(club_id));
create policy events_manage_manager on public.events for all to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));

create or replace function public.get_public_events(target_club_slug text)
returns table (id uuid, title text, description text, location text, start_at timestamptz, end_at timestamptz, type public.event_type, visibility public.visibility)
language sql security definer set search_path = public
as $$
  select e.id, e.title, e.description, e.location, e.start_at, e.end_at, e.type, e.visibility
  from public.events e join public.clubs c on c.id = e.club_id
  where c.slug::text = lower(target_club_slug) and c.status = 'active' and e.visibility = 'public' and e.end_at >= timezone('utc', now())
  order by e.start_at;
$$;

revoke all on function public.get_public_events(text) from public;
grant execute on function public.get_public_events(text) to anon, authenticated;
