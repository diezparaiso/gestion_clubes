create table public.seasons (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  name text not null,
  start_date date not null,
  end_date date not null,
  is_current boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (club_id, name),
  check (end_date > start_date)
);

create table public.teams (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  name text not null,
  category text not null,
  season_id uuid not null references public.seasons(id) on delete restrict,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (club_id, season_id, name)
);

create unique index seasons_one_current_idx on public.seasons (club_id) where is_current = true;
create index teams_club_season_idx on public.teams (club_id, season_id);

create trigger seasons_set_updated_at before update on public.seasons
for each row execute function public.set_updated_at();
create trigger teams_set_updated_at before update on public.teams
for each row execute function public.set_updated_at();

alter table public.seasons enable row level security;
alter table public.teams enable row level security;

create policy seasons_select_member on public.seasons
for select to authenticated using (public.is_club_member(club_id));
create policy seasons_manage_manager on public.seasons
for all to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));
create policy teams_select_member on public.teams
for select to authenticated using (public.is_club_member(club_id));
create policy teams_manage_manager on public.teams
for all to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));
