-- Enum para estado de patrocinio
create type public.sponsor_status as enum (
  'active', 'pending', 'expired', 'cancelled', 'paused'
);

-- Tabla de patrocinadores
create table public.sponsors (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  logo_url text,
  website text,
  contact_email citext,
  contact_phone text,
  contract_start_date date not null,
  contract_end_date date not null,
  annual_amount decimal(12, 2) not null check (annual_amount > 0),
  benefits text,
  status public.sponsor_status not null default 'pending',
  is_public boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint sponsors_dates_valid check (contract_end_date >= contract_start_date)
);

create index sponsors_club_status_idx on public.sponsors (club_id, status);
create index sponsors_club_public_idx on public.sponsors (club_id) where is_public = true;
create index sponsors_club_active_idx on public.sponsors (club_id, status) 
  where status = 'active' and is_public = true;

create trigger sponsors_set_updated_at before update on public.sponsors
for each row execute function public.set_updated_at();

alter table public.sponsors enable row level security;

-- Managers ven todos los patrocinadores del club
create policy sponsors_select_manager on public.sponsors
for select to authenticated using (public.is_club_manager(club_id));

-- Managers pueden gestionar patrocinadores
create policy sponsors_manage_manager on public.sponsors
for all to authenticated using (public.is_club_manager(club_id))
with check (public.is_club_manager(club_id));

-- Función para obtener patrocinadores públicos
create or replace function public.get_public_sponsors(target_club_slug text)
returns table (
  id uuid,
  name text,
  logo_url text,
  website text,
  contact_email citext
)
language sql stable security definer
set search_path = public
as $$
  select s.id, s.name, s.logo_url, s.website, s.contact_email
  from public.sponsors s
  join public.clubs c on c.id = s.club_id
  where c.slug::text = lower(target_club_slug)
    and s.status = 'active'
    and s.is_public = true
    and s.contract_start_date <= current_date
    and s.contract_end_date >= current_date
  order by s.name asc;
$$;

revoke all on function public.get_public_sponsors(text) from public;
grant execute on function public.get_public_sponsors(text) to anon, authenticated;

-- RPC para crear patrocinador (solo managers)
create or replace function public.create_sponsor(
  p_club_id uuid,
  p_name text,
  p_website text,
  p_contact_email citext,
  p_contact_phone text,
  p_contract_start_date date,
  p_contract_end_date date,
  p_annual_amount decimal,
  p_benefits text,
  p_is_public boolean
)
returns table (success boolean, message text, sponsor_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sponsor_id uuid;
begin
  -- Verificar que el caller es manager
  if not public.is_club_manager(p_club_id) then
    return query select false, 'Solo managers pueden crear patrocinadores'::text, null::uuid;
    return;
  end if;

  -- Validar datos
  if length(trim(p_name)) = 0 then
    return query select false, 'El nombre es requerido'::text, null::uuid;
    return;
  end if;

  if p_annual_amount <= 0 then
    return query select false, 'El monto debe ser mayor a 0'::text, null::uuid;
    return;
  end if;

  if p_contract_end_date < p_contract_start_date then
    return query select false, 'La fecha final debe ser después de la inicial'::text, null::uuid;
    return;
  end if;

  -- Insertar patrocinador
  insert into public.sponsors (
    club_id, name, website, contact_email, contact_phone,
    contract_start_date, contract_end_date, annual_amount, benefits, is_public
  )
  values (
    p_club_id, trim(p_name), p_website, p_contact_email, p_contact_phone,
    p_contract_start_date, p_contract_end_date, p_annual_amount, p_benefits, p_is_public
  )
  returning id into v_sponsor_id;

  -- Registrar en auditoría
  insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
  values (
    p_club_id,
    auth.uid(),
    'create',
    'sponsor',
    v_sponsor_id,
    jsonb_build_object('name', p_name, 'amount', p_annual_amount)
  );

  return query select true, 'Patrocinador creado'::text, v_sponsor_id;
end;
$$;

revoke all on function public.create_sponsor(uuid, text, text, citext, text, date, date, decimal, text, boolean) from public;
grant execute on function public.create_sponsor(uuid, text, text, citext, text, date, date, decimal, text, boolean) to authenticated;

-- RPC para actualizar patrocinador
create or replace function public.update_sponsor(
  p_sponsor_id uuid,
  p_name text,
  p_website text,
  p_contact_email citext,
  p_contact_phone text,
  p_annual_amount decimal,
  p_benefits text,
  p_status public.sponsor_status,
  p_is_public boolean
)
returns table (success boolean, message text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_club_id uuid;
begin
  -- Obtener club_id y verificar permisos
  select club_id into v_club_id from public.sponsors where id = p_sponsor_id;
  
  if v_club_id is null then
    return query select false, 'Patrocinador no encontrado'::text;
    return;
  end if;

  if not public.is_club_manager(v_club_id) then
    return query select false, 'Solo managers pueden actualizar patrocinadores'::text;
    return;
  end if;

  -- Actualizar
  update public.sponsors
  set
    name = trim(p_name),
    website = p_website,
    contact_email = p_contact_email,
    contact_phone = p_contact_phone,
    annual_amount = p_annual_amount,
    benefits = p_benefits,
    status = p_status,
    is_public = p_is_public
  where id = p_sponsor_id;

  -- Registrar en auditoría
  insert into public.audit_logs (club_id, actor_profile_id, action, entity_type, entity_id, data)
  values (
    v_club_id,
    auth.uid(),
    'update',
    'sponsor',
    p_sponsor_id,
    jsonb_build_object('name', p_name, 'status', p_status::text)
  );

  return query select true, 'Patrocinador actualizado'::text;
end;
$$;

revoke all on function public.update_sponsor(uuid, text, text, citext, text, decimal, text, public.sponsor_status, boolean) from public;
grant execute on function public.update_sponsor(uuid, text, text, citext, text, decimal, text, public.sponsor_status, boolean) to authenticated;