create type public.raffle_status as enum ('draft', 'scheduled', 'active', 'sold_out', 'closed', 'drawn', 'cancelled');
create type public.ticket_payment_status as enum ('pending', 'paid', 'failed', 'cancelled', 'refunded');
create type public.draw_method as enum ('manual', 'random_number', 'external_evidence');

create table public.raffles (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  slug citext not null,
  title text not null,
  description text,
  image_url text,
  ticket_price numeric(12,2) not null check (ticket_price > 0),
  total_numbers integer not null check (total_numbers > 0),
  start_at timestamptz not null,
  end_at timestamptz not null,
  draw_at timestamptz not null,
  status public.raffle_status not null default 'draft',
  terms_url text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (club_id, slug), check (end_at > start_at), check (draw_at >= end_at)
);

create table public.raffle_tickets (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  raffle_id uuid not null references public.raffles(id) on delete restrict,
  number integer not null check (number >= 0),
  buyer_profile_id uuid references public.profiles(id),
  buyer_name text not null,
  buyer_email citext not null,
  buyer_phone text,
  payment_status public.ticket_payment_status not null default 'pending',
  payment_reference text,
  purchased_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (raffle_id, number)
);

create table public.raffle_draws (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  raffle_id uuid not null references public.raffles(id) on delete restrict,
  drawn_at timestamptz not null default timezone('utc', now()),
  method public.draw_method not null,
  winning_number integer not null,
  winning_ticket_id uuid not null references public.raffle_tickets(id),
  executed_by uuid not null references public.profiles(id),
  evidence_url text,
  result_snapshot jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  unique (raffle_id)
);

create index raffle_tickets_raffle_idx on public.raffle_tickets (raffle_id, payment_status);
create trigger raffles_set_updated_at before update on public.raffles for each row execute function public.set_updated_at();
create trigger raffle_tickets_set_updated_at before update on public.raffle_tickets for each row execute function public.set_updated_at();
alter table public.raffles enable row level security;
alter table public.raffle_tickets enable row level security;
alter table public.raffle_draws enable row level security;
create policy raffles_select_member on public.raffles for select to authenticated using (public.is_club_member(club_id));
create policy raffles_select_public on public.raffles for select to anon using (status = 'active');
create policy clubs_select_public_raffle on public.clubs for select to anon using (exists (select 1 from public.raffles where raffles.club_id = clubs.id and raffles.status = 'active'));
create policy raffles_manage_manager on public.raffles for all to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));
create policy raffle_tickets_select_manager on public.raffle_tickets for select to authenticated using (public.is_club_manager(club_id));
create policy raffle_draws_select_manager on public.raffle_draws for select to authenticated using (public.is_club_manager(club_id));

create or replace function public.get_public_raffle_numbers(target_club_slug text, target_raffle_slug text)
returns table (number integer)
language sql
security definer
set search_path = public
as $$
  select t.number
  from public.raffle_tickets t
  join public.raffles r on r.id = t.raffle_id
  join public.clubs c on c.id = r.club_id
  where c.slug::text = lower(target_club_slug)
    and r.slug::text = lower(target_raffle_slug)
    and r.status = 'active'
    and t.payment_status in ('pending', 'paid')
  order by t.number;
$$;

revoke all on function public.get_public_raffle_numbers(text, text) from public;
grant execute on function public.get_public_raffle_numbers(text, text) to anon, authenticated;
