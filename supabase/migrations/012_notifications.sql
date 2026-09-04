create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  body text not null check (length(trim(body)) > 0),
  type text not null check (type in ('news', 'event', 'raffle', 'system', 'other')),
  target text not null default 'all_members' check (target in ('all_members', 'managers', 'members', 'staff')),
  created_at timestamptz not null default timezone('utc', now())
);

create index notifications_club_created_idx on public.notifications (club_id, created_at desc);
alter table public.notifications enable row level security;
create policy notifications_select_member on public.notifications for select to authenticated using (public.is_club_member(club_id));
create policy notifications_manage_manager on public.notifications for all to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));