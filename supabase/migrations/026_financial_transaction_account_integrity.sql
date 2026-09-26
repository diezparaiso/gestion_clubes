-- MODIFICADO POR GPT-5.6 LUNA (2026-09-26): Refuerza la integridad entre movimientos financieros y cuentas del mismo club.
-- Evita que una transacción de un club apunte a una cuenta financiera de otro club.

create or replace function public.validate_financial_transaction_account()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_account_club_id uuid;
begin
  select club_id
    into v_account_club_id
  from public.financial_accounts
  where id = new.account_id;

  if v_account_club_id is null then
    raise exception 'La cuenta financiera no existe';
  end if;

  if v_account_club_id <> new.club_id then
    raise exception 'La cuenta financiera no pertenece al club de la transacción';
  end if;

  return new;
end;
$$;

drop trigger if exists financial_transaction_account_club_check on public.financial_transactions;

create trigger financial_transaction_account_club_check
before insert or update of club_id, account_id
on public.financial_transactions
for each row
execute function public.validate_financial_transaction_account();

revoke all on function public.validate_financial_transaction_account() from public;
grant execute on function public.validate_financial_transaction_account() to authenticated;
