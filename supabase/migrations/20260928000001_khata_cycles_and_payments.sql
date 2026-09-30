-- Traditional khata-book practice: a customer's purchases keep landing as
-- new rows on their open (unsettled) khata cycle instead of each becoming
-- its own khata; once that cycle is fully paid off, their next purchase
-- opens a fresh one. Payments are now their own recorded events too, so the
-- full history of a cycle (every purchase and every payment) stays visible.

-- Khatas need an update policy: create_khata now updates an open cycle's
-- totals, and record_khata_payment bumps paid_amount.
create policy khatas_update on public.khatas for update to authenticated
  using (tenant_id = (select public.current_tenant_id()))
  with check (tenant_id = (select public.current_tenant_id()));

grant update on public.khatas to authenticated;

-- Payment history -------------------------------------------------------------

create table public.khata_payments (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null default public.current_tenant_id() references public.tenants (id) on delete cascade,
  khata_id    uuid not null references public.khatas (id) on delete cascade,
  amount      numeric(12, 0) not null check (amount > 0),
  created_at  timestamptz not null default clock_timestamp()
);

create index khata_payments_khata_idx  on public.khata_payments (khata_id);
create index khata_payments_tenant_idx on public.khata_payments (tenant_id);

alter table public.khata_payments enable row level security;

-- A payment belongs to a tenant through its khata, same shape as khata_items.
create policy khata_payments_select on public.khata_payments for select to authenticated
  using (exists (
    select 1 from public.khatas k
    where k.id = khata_id and k.tenant_id = (select public.current_tenant_id())
  ));
create policy khata_payments_insert on public.khata_payments for insert to authenticated
  with check (exists (
    select 1 from public.khatas k
    where k.id = khata_id and k.tenant_id = (select public.current_tenant_id())
  ));

grant select, insert on public.khata_payments to authenticated;

-- create_khata: append to the customer's open cycle when they have one ------

create or replace function public.create_khata(
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
  v_customer_id       uuid;
  v_new_total         numeric;
  v_found             int;
  v_khata_id          uuid;
  v_existing          public.khatas%rowtype;
  v_combined_total    numeric;
  v_combined_discount numeric;
  v_combined_paid     numeric;
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

  select count(*), coalesce(sum(i.price * u.qty), 0) into v_found, v_new_total
  from unnest(p_item_ids, p_quantities) as u(id, qty)
  join public.items i on i.id = u.id;

  if v_found <> array_length(p_item_ids, 1) then
    raise exception 'One or more items were not found';
  end if;

  -- The customer's most recent still-open (unsettled) cycle, if any.
  select * into v_existing
  from public.khatas
  where customer_id = v_customer_id
    and tenant_id = (select public.current_tenant_id())
    and (total_amount - discount - paid_amount) > 0
  order by created_at desc
  limit 1;

  if found then
    v_combined_total    := v_existing.total_amount + v_new_total;
    v_combined_discount := v_existing.discount + coalesce(p_discount, 0);
    v_combined_paid     := v_existing.paid_amount + coalesce(p_paid, 0);
  else
    v_combined_total    := v_new_total;
    v_combined_discount := coalesce(p_discount, 0);
    v_combined_paid     := coalesce(p_paid, 0);
  end if;

  if v_combined_discount + v_combined_paid > v_combined_total then
    raise exception 'Discount and paid amount can''t be more than the items total';
  end if;

  if found then
    update public.khatas
    set total_amount = v_combined_total,
        discount     = v_combined_discount,
        paid_amount  = v_combined_paid
    where id = v_existing.id;
    v_khata_id := v_existing.id;
  else
    insert into public.khatas (customer_id, total_amount, discount, paid_amount)
    values (v_customer_id, v_combined_total, v_combined_discount, v_combined_paid)
    returning id into v_khata_id;
  end if;

  -- created_at ticks per row (clock_timestamp), which keeps the selection
  -- order and gives each line its own purchase date.
  insert into public.khata_items (khata_id, item_id, item_name, item_price, quantity, item_unit)
  select v_khata_id, i.id, i.name, i.price, u.qty, i.unit
  from unnest(p_item_ids, p_quantities) with ordinality as u(id, qty, ord)
  join public.items i on i.id = u.id
  order by u.ord;

  return v_khata_id;
end;
$$;

-- record_khata_payment: bump paid_amount and log the payment atomically ------

create function public.record_khata_payment(
  p_khata_id uuid,
  p_amount   numeric
) returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_payment_id uuid;
begin
  if coalesce(p_amount, 0) <= 0 then
    raise exception 'Enter a payment amount greater than 0';
  end if;

  update public.khatas
  set paid_amount = paid_amount + p_amount
  where id = p_khata_id
    and tenant_id = (select public.current_tenant_id());

  if not found then
    raise exception 'Khata not found';
  end if;

  insert into public.khata_payments (khata_id, amount)
  values (p_khata_id, p_amount)
  returning id into v_payment_id;

  return v_payment_id;
end;
$$;

revoke all on function public.record_khata_payment(uuid, numeric) from public, anon;
grant execute on function public.record_khata_payment(uuid, numeric) to authenticated;
