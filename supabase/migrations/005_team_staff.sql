create table public.team_staff (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete restrict,
  role text not null,
  start_date date not null default current_date,
  end_date date,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (end_date is null or end_date >= start_date),
  unique (team_id, profile_id, role)
);

create index team_staff_team_idx on public.team_staff (team_id, is_active);
create trigger team_staff_set_updated_at before update on public.team_staff
for each row execute function public.set_updated_at();
alter table public.team_staff enable row level security;
create policy team_staff_select_member on public.team_staff
for select to authenticated using (public.is_club_member(club_id));
create policy team_staff_manage_manager on public.team_staff
for all to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));
