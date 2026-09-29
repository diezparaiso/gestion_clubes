-- MODIFICADO POR GPT-5.6 LUNA (2026-09-29): alinea patrocinadores con la matriz central de permisos.
-- No se ejecuta automáticamente sobre Supabase remoto.
--
-- Hallazgo de la auditoría:
-- Flutter ya exige sponsors_manage, pero la migración 032 no incluía ese
-- permiso en el enum y 019 usaba is_club_manager, que también permitía
-- al secretario gestionar patrocinadores. Esta migración corrige ambas
-- discrepancias sin modificar migraciones históricas.

drop policy if exists sponsors_select_manager on public.sponsors;
create policy sponsors_select_permission on public.sponsors
for select to authenticated
using (public.has_club_permission(club_id, 'sponsors_manage'));

drop policy if exists sponsors_manage_manager on public.sponsors;
create policy sponsors_manage_permission on public.sponsors
for all to authenticated
using (public.has_club_permission(club_id, 'sponsors_manage'))
with check (public.has_club_permission(club_id, 'sponsors_manage'));

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
returns table(success boolean, message text, sponsor_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sponsor_id uuid;
begin
  if not public.has_club_permission(p_club_id, 'sponsors_manage') then
    return query select false, 'No tienes permiso para gestionar patrocinadores'::text, null::uuid;
    return;
  end if;

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

  insert into public.sponsors (
    club_id, name, website, contact_email, contact_phone,
    contract_start_date, contract_end_date, annual_amount, benefits, is_public
  )
  values (
    p_club_id, trim(p_name), p_website, p_contact_email, p_contact_phone,
    p_contract_start_date, p_contract_end_date, p_annual_amount, p_benefits, p_is_public
  )
  returning id into v_sponsor_id;

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
returns table(success boolean, message text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_club_id uuid;
begin
  select club_id into v_club_id
  from public.sponsors
  where id = p_sponsor_id;

  if v_club_id is null then
    return query select false, 'Patrocinador no encontrado'::text;
    return;
  end if;

  if not public.has_club_permission(v_club_id, 'sponsors_manage') then
    return query select false, 'No tienes permiso para gestionar patrocinadores'::text;
    return;
  end if;

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
