create type public.membership_status as enum ('active', 'pending', 'expired', 'cancelled', 'deceased', 'suspended');
create type public.membership_type as enum ('standard', 'youth', 'family', 'supporter', 'other');

create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete restrict,
  member_number integer not null check (member_number > 0),
  membership_type public.membership_type not null default 'standard',
  status public.membership_status not null default 'pending',
  join_date date not null default current_date,
  renewal_date date,
  leave_date date,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (club_id, member_number),
  constraint memberships_leave_after_join check (leave_date is null or leave_date >= join_date)
);

create unique index memberships_one_active_profile_idx
  on public.memberships (club_id, profile_id)
  where status = 'active';
create index memberships_club_number_idx on public.memberships (club_id, member_number);

create trigger memberships_set_updated_at before update on public.memberships
for each row execute function public.set_updated_at();

alter table public.memberships enable row level security;

create policy memberships_select_member on public.memberships
for select to authenticated using (public.is_club_member(club_id));
create policy memberships_insert_manager on public.memberships
for insert to authenticated with check (public.is_club_manager(club_id));
create policy memberships_update_manager on public.memberships
for update to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));

create policy profiles_select_club_manager on public.profiles
for select to authenticated using (
  exists (
    select 1 from public.memberships m
    where m.profile_id = profiles.id and public.is_club_manager(m.club_id)
  )
);
