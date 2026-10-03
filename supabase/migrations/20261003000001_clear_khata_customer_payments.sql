-- Payments clear a customer's overall outstanding khata, not one khata record.
-- The amount is applied oldest-open-khata first; each allocation is still
-- logged against its khata in khata_payments, so every khata record and its
-- payment history stays intact after it is cleared.

drop function public.record_khata_payment(uuid, numeric);

create function public.record_customer_payment(
  p_customer_id uuid,
  p_amount      numeric
) returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_tenant_id   uuid := (select public.current_tenant_id());
  v_outstanding numeric;
  v_left        numeric := p_amount;
  v_khata       record;
  v_owed        numeric;
  v_apply       numeric;
begin
  if coalesce(p_amount, 0) <= 0 then
    raise exception 'Enter a payment amount greater than 0';
  end if;

  if not exists (select 1 from public.customers where id = p_customer_id and tenant_id = v_tenant_id) then
    raise exception 'Customer not found';
  end if;

  select coalesce(sum(total_amount - discount - paid_amount), 0) into v_outstanding
  from public.khatas
  where customer_id = p_customer_id
    and tenant_id = v_tenant_id
    and (total_amount - discount - paid_amount) > 0;

  if v_outstanding <= 0 then
    raise exception 'This customer has no outstanding khata';
  end if;

  if p_amount > v_outstanding then
    raise exception 'That payment is more than the outstanding amount (%)', v_outstanding;
  end if;

  for v_khata in
    select id, total_amount, discount, paid_amount
    from public.khatas
    where customer_id = p_customer_id
      and tenant_id = v_tenant_id
      and (total_amount - discount - paid_amount) > 0
    order by created_at asc
  loop
    exit when v_left <= 0;

    v_owed  := v_khata.total_amount - v_khata.discount - v_khata.paid_amount;
    v_apply := least(v_owed, v_left);

    update public.khatas set paid_amount = paid_amount + v_apply where id = v_khata.id;
    insert into public.khata_payments (khata_id, amount) values (v_khata.id, v_apply);

    v_left := v_left - v_apply;
  end loop;
end;
$$;

revoke all on function public.record_customer_payment(uuid, numeric) from public, anon;
grant execute on function public.record_customer_payment(uuid, numeric) to authenticated;
