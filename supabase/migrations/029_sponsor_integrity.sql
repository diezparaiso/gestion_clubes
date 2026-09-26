-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Refuerza la integridad de patrocinadores a nivel de base de datos.
-- Las fechas y el importe quedan protegidos independientemente del cliente Flutter.

create or replace function public.validate_sponsor_integrity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if trim(coalesce(new.name, '')) = '' then
    raise exception 'El nombre del patrocinador es obligatorio';
  end if;

  if new.contract_end_date < new.contract_start_date then
    raise exception 'La fecha de fin no puede ser anterior a la fecha de inicio';
  end if;

  if new.annual_amount < 0 then
    raise exception 'El importe anual no puede ser negativo';
  end if;

  if not public.is_club_manager(new.club_id) then
    raise exception 'No tienes permisos para modificar este patrocinador';
  end if;

  return new;
end;
$$;

drop trigger if exists sponsors_integrity_check on public.sponsors;
create trigger sponsors_integrity_check
before insert or update
on public.sponsors
for each row
execute function public.validate_sponsor_integrity();

revoke all on function public.validate_sponsor_integrity() from public;
grant execute on function public.validate_sponsor_integrity() to authenticated;
