-- Payment method on payments received (clearing a khata): Cash or Online.
--
-- Nullable on purpose: the shopkeeper may leave it unselected, and every
-- payment recorded before this change (or taken together with a purchase)
-- simply has no method. Nothing existing is modified or back-filled.

begin;

alter table public.khata_payments
  add column payment_method text
    check (payment_method is null or payment_method in ('cash', 'online'));

-- record_customer_payment gains an optional method. The signature changes, so
-- the old two-argument function is dropped first (leaving both would make a
-- call with two named arguments ambiguous).
drop function public.record_customer_payment(uuid, numeric);

create function public.record_customer_payment(
  p_customer_id uuid,
  p_amount      numeric,
  p_method      text default null
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
  v_payment_id  uuid := gen_random_uuid();
  v_now         timestamptz := clock_timestamp();
  v_method      text := nullif(btrim(lower(coalesce(p_method, ''))), '');
begin
  if coalesce(p_amount, 0) <= 0 then
    raise exception 'Enter a payment amount greater than 0';
  end if;

  if v_method is not null and v_method not in ('cash', 'online') then
    raise exception 'Choose Cash or Online as the payment method';
  end if;

  if not exists (select 1 from public.customers where id = p_customer_id and tenant_id = v_tenant_id) then
    raise exception 'Customer not found';
  end if;

  -- Lock the open khatas so concurrent payments can't over-apply.
  perform 1 from public.khatas
  where customer_id = p_customer_id and tenant_id = v_tenant_id
    and (total_amount - discount - paid_amount) > 0
  for update;

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
    insert into public.khata_payments (khata_id, amount, payment_id, created_at, payment_method)
    values (v_khata.id, v_apply, v_payment_id, v_now, v_method);

    v_left := v_left - v_apply;
  end loop;
end;
$$;

revoke all on function public.record_customer_payment(uuid, numeric, text) from public, anon;
grant execute on function public.record_customer_payment(uuid, numeric, text) to authenticated;

commit;
