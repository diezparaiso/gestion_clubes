do $$
begin
  create type public.audit_action as enum ('create', 'update', 'delete', 'login', 'export', 'payment', 'raffle_draw', 'permission_change');
exception
  when duplicate_object then null;
end;
$$;

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  club_id uuid references public.clubs(id) on delete set null,
  actor_profile_id uuid references public.profiles(id) on delete set null,
  action public.audit_action not null,
  entity_type text not null check (length(trim(entity_type)) > 0),
  entity_id uuid,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index audit_logs_club_created_idx on public.audit_logs (club_id, created_at desc);
alter table public.audit_logs enable row level security;
create policy audit_logs_select_manager on public.audit_logs for select to authenticated using (club_id is not null and public.is_club_manager(club_id));

create or replace function public.prevent_audit_log_mutation()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  raise exception 'Los registros de auditoría son inmutables';
end;
$$;

create trigger audit_logs_immutable_update before update or delete on public.audit_logs
for each row execute function public.prevent_audit_log_mutation();

create or replace function public.audit_raffle_draw_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
  values (
    new.club_id,
    new.executed_by,
    'raffle_draw',
    'raffle_draw',
    new.id,
    jsonb_build_object('raffle_id', new.raffle_id, 'winning_number', new.winning_number, 'method', new.method)
  );
  return new;
end;
$$;

create trigger raffle_draw_audit_insert after insert on public.raffle_draws
for each row execute function public.audit_raffle_draw_insert();

revoke all on function public.prevent_audit_log_mutation() from public;
revoke all on function public.audit_raffle_draw_insert() from public;
