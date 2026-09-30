-- Items are sold by the unit (e.g. Rs 500 per kg) and a khata line now
-- records how many units of that item were taken, not just a flat price.

alter table public.items
  add column unit text not null default 'piece' check (length(btrim(unit)) > 0);

alter table public.khata_items
  add column quantity  numeric(12, 3) not null default 1 check (quantity > 0),
  add column item_unit text not null default 'piece' check (length(btrim(item_unit)) > 0);

-- create_khata gains a parallel p_quantities array; the signature changes so
-- the old function is dropped first rather than replaced.
drop function public.create_khata(uuid, uuid[], numeric, numeric);

create function public.create_khata(
  p_customer_id uuid,
  p_item_ids    uuid[],
  p_quantities  numeric[],
  p_discount    numeric,
  p_paid        numeric
) returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_customer_id uuid;
  v_total       numeric;
  v_found       int;
  v_khata_id    uuid;
begin
  if coalesce(array_length(p_item_ids, 1), 0) = 0 then
    raise exception 'Select at least one item';
  end if;

  if array_length(p_item_ids, 1) <> array_length(p_quantities, 1) then
    raise exception 'Item and quantity lists don''t match';
  end if;

  if exists (select 1 from unnest(p_quantities) q where q <= 0) then
    raise exception 'Enter a quantity greater than 0 for every item';
  end if;

  select id into v_customer_id from public.customers where id = p_customer_id;
  if v_customer_id is null then
    raise exception 'Customer not found';
  end if;

  select count(*), coalesce(sum(i.price * u.qty), 0) into v_found, v_total
  from unnest(p_item_ids, p_quantities) as u(id, qty)
  join public.items i on i.id = u.id;

  if v_found <> array_length(p_item_ids, 1) then
    raise exception 'One or more items were not found';
  end if;

  if coalesce(p_discount, 0) + coalesce(p_paid, 0) > v_total then
    raise exception 'Discount and paid amount can''t be more than the items total';
  end if;

  insert into public.khatas (customer_id, total_amount, discount, paid_amount)
  values (v_customer_id, v_total, coalesce(p_discount, 0), coalesce(p_paid, 0))
  returning id into v_khata_id;

  -- created_at ticks per row (clock_timestamp), which keeps the selection order.
  insert into public.khata_items (khata_id, item_id, item_name, item_price, quantity, item_unit)
  select v_khata_id, i.id, i.name, i.price, u.qty, i.unit
  from unnest(p_item_ids, p_quantities) with ordinality as u(id, qty, ord)
  join public.items i on i.id = u.id
  order by u.ord;

  return v_khata_id;
end;
$$;

revoke all on function public.create_khata(uuid, uuid[], numeric[], numeric, numeric) from public, anon;
grant execute on function public.create_khata(uuid, uuid[], numeric[], numeric, numeric) to authenticated;
