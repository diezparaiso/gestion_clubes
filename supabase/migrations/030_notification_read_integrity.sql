-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Refuerza aislamiento de notificaciones por club y usuario.
-- Evita que un usuario pueda marcar como leída una entrega de otro perfil.

create or replace function public.mark_notification_delivery_read(p_delivery_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.notification_deliveries
  set read_at = timezone('utc', now())
  where id = p_delivery_id
    and profile_id = auth.uid();
end;
$$;

create or replace function public.mark_all_notification_deliveries_read()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.notification_deliveries
  set read_at = timezone('utc', now())
  where profile_id = auth.uid()
    and read_at is null;
end;
$$;

revoke all on function public.mark_notification_delivery_read(uuid) from public;
grant execute on function public.mark_notification_delivery_read(uuid) to authenticated;
revoke all on function public.mark_all_notification_deliveries_read() from public;
grant execute on function public.mark_all_notification_deliveries_read() to authenticated;
