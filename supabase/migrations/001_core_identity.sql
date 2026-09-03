create extension if not exists pgcrypto;
create extension if not exists citext;

create type public.club_status as enum ('active', 'suspended', 'closed');
create type public.club_role as enum (
  'club_president', 'club_treasurer', 'club_secretary', 'team_manager',
  'coach', 'staff', 'member', 'parent_guardian', 'player', 'follower'
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text,
  last_name text,
  email citext not null,
  phone text,
  date_of_birth date,
  avatar_url text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.clubs (
  id uuid primary key default gen_random_uuid(),
  legal_name text not null,
  public_name text not null,
  slug citext not null unique,
  tax_id text,
  address text,
  postal_code text,
  city text,
  province text,
  country text not null default 'ES',
  email citext,
  phone text,
  website text,
  logo_url text,
  facebook_url text,
  instagram_url text,
  x_url text,
  youtube_url text,
  tiktok_url text,
  privacy_policy_url text,
  status public.club_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint clubs_slug_format check (slug::text ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
);

create table public.club_memberships (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role public.club_role not null,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (club_id, profile_id, role)
);

create or replace function public.set_updated_at()
returns trigger language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
create trigger clubs_set_updated_at before update on public.clubs
for each row execute function public.set_updated_at();
create trigger club_memberships_set_updated_at before update on public.club_memberships
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do update set email = excluded.email;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_platform_admin()
returns boolean language sql stable security definer
set search_path = public
as $$
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'platform_admin')::boolean, false);
$$;

create or replace function public.is_club_member(target_club_id uuid)
returns boolean language sql stable security definer
set search_path = public
as $$
  select public.is_platform_admin() or exists (
    select 1 from public.club_memberships
    where club_id = target_club_id and profile_id = auth.uid() and is_active
  );
$$;

create or replace function public.is_club_manager(target_club_id uuid)
returns boolean language sql stable security definer
set search_path = public
as $$
  select public.is_platform_admin() or exists (
    select 1 from public.club_memberships
    where club_id = target_club_id
      and profile_id = auth.uid()
      and is_active
      and role in ('club_president', 'club_secretary')
  );
$$;

alter table public.profiles enable row level security;
alter table public.clubs enable row level security;
alter table public.club_memberships enable row level security;

create policy profiles_select_own on public.profiles
for select to authenticated using (id = auth.uid());
create policy profiles_update_own on public.profiles
for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy clubs_select_member on public.clubs
for select to authenticated using (public.is_club_member(id));
create policy clubs_update_manager on public.clubs
for update to authenticated using (public.is_club_manager(id)) with check (public.is_club_manager(id));

create policy club_memberships_select_member on public.club_memberships
for select to authenticated using (public.is_club_member(club_id));
create policy club_memberships_manage_manager on public.club_memberships
for all to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));

create or replace function public.create_club(
  club_public_name text,
  club_legal_name text,
  club_slug text
)
returns table (id uuid, public_name text, slug citext)
language plpgsql
security definer
set search_path = public
as $$
declare
  created_club public.clubs;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  insert into public.clubs (public_name, legal_name, slug)
  values (trim(club_public_name), trim(club_legal_name), lower(trim(club_slug)))
  returning * into created_club;

  insert into public.club_memberships (club_id, profile_id, role)
  values (created_club.id, auth.uid(), 'club_president');

  return query select created_club.id, created_club.public_name, created_club.slug;
end;
$$;

revoke all on function public.create_club(text, text, text) from public;
grant execute on function public.create_club(text, text, text) to authenticated;
