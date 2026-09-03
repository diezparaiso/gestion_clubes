create table public.players (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (club_id, profile_id)
);

create table public.team_players (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  player_id uuid not null references public.players(id) on delete restrict,
  jersey_number smallint check (jersey_number is null or jersey_number between 0 and 99),
  joined_at date not null default current_date,
  left_at date,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  check (left_at is null or left_at >= joined_at),
  unique (team_id, player_id)
);

create index team_players_team_idx on public.team_players (team_id, jersey_number);
create trigger players_set_updated_at before update on public.players for each row execute function public.set_updated_at();
create trigger team_players_set_updated_at before update on public.team_players for each row execute function public.set_updated_at();
alter table public.players enable row level security;
alter table public.team_players enable row level security;
create policy players_select_member on public.players for select to authenticated using (public.is_club_member(club_id));
create policy players_manage_manager on public.players for all to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));
create policy team_players_select_member on public.team_players for select to authenticated using (public.is_club_member(club_id));
create policy team_players_manage_manager on public.team_players for all to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));
