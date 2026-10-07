-- Borrador solamente: revisar y aplicar manualmente; no ejecutado.
-- Sustituye el INSERT REST con RETURNING por una RPC que crea la notificación
-- y permite que el trigger AFTER INSERT materialice las entregas.

create or replace function public.create_notification(
  p_club_id uuid,
  p_title text,
  p_body text,
  p_type text,
  p_target text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_notification_id uuid;
begin
  if not public.is_club_manager(p_club_id) then
    raise exception 'No tienes permiso para crear notificaciones';
  end if;

  if p_title is null or length(trim(p_title)) = 0 then
    raise exception 'El título de la notificación es obligatorio';
  end if;
  if p_body is null or length(trim(p_body)) = 0 then
    raise exception 'El contenido de la notificación es obligatorio';
  end if;
  if p_type is null or p_type not in (
    'news',
    'event',
    'raffle',
    'system',
    'other',
    'raffle_winner',
    'raffle_monthly_result'
  ) then
    raise exception 'El tipo de notificación no es válido';
  end if;
  if p_target is null or p_target not in (
    'all_members',
    'managers',
    'members',
    'staff',
    'profile'
  ) then
    raise exception 'El destinatario de la notificación no es válido';
  end if;

  insert into public.notifications (club_id, title, body, type, target)
  values (
    p_club_id,
    trim(p_title),
    trim(p_body),
    p_type,
    p_target
  )
  returning id into v_notification_id;

  return v_notification_id;
end;
$$;

revoke all on function public.create_notification(uuid, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.create_notification(uuid, text, text, text, text)
  to authenticated;

revoke insert on table public.notifications from public, anon, authenticated;
revoke insert (club_id, title, body, type, target)
  on table public.notifications from public, anon, authenticated;
