create type public.account_type as enum ('bank', 'cash', 'other');
create type public.transaction_type as enum ('income', 'expense');
create type public.transaction_category as enum ('membership', 'sponsorship', 'raffle', 'event', 'equipment', 'federation', 'facilities', 'salaries', 'supplies', 'other');

create table public.financial_accounts (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  name text not null,
  account_type public.account_type not null,
  opening_balance numeric(12,2) not null default 0,
  current_balance numeric(12,2) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.financial_transactions (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  account_id uuid not null references public.financial_accounts(id) on delete restrict,
  type public.transaction_type not null,
  category public.transaction_category not null,
  amount numeric(12,2) not null check (amount > 0),
  transaction_date date not null default current_date,
  description text not null,
  reference text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.create_default_financial_account()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.financial_accounts (club_id, name, account_type)
  values (new.id, 'Cuenta principal', 'bank');
  return new;
end;
$$;

create trigger clubs_create_default_financial_account
after insert on public.clubs
for each row execute function public.create_default_financial_account();

create index financial_transactions_account_date_idx on public.financial_transactions (account_id, transaction_date desc);
create trigger financial_accounts_set_updated_at before update on public.financial_accounts for each row execute function public.set_updated_at();
create trigger financial_transactions_set_updated_at before update on public.financial_transactions for each row execute function public.set_updated_at();
alter table public.financial_accounts enable row level security;
alter table public.financial_transactions enable row level security;
create policy financial_accounts_select_manager on public.financial_accounts for select to authenticated using (public.is_club_manager(club_id));
create policy financial_accounts_manage_manager on public.financial_accounts for all to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));
create policy financial_transactions_select_manager on public.financial_transactions for select to authenticated using (public.is_club_manager(club_id));
create policy financial_transactions_insert_manager on public.financial_transactions for insert to authenticated with check (public.is_club_manager(club_id) and created_by = auth.uid());
create policy financial_transactions_update_manager on public.financial_transactions for update to authenticated using (public.is_club_manager(club_id)) with check (public.is_club_manager(club_id));
