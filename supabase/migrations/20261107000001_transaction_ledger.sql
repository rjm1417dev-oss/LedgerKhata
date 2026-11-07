-- Transaction-level ledger.
--
-- Every purchase and every payment is its own immutable, timestamped record,
-- so a customer can buy several times and pay several times on the same day
-- without anything being merged:
--
--   khata_purchases   NEW  one row per purchase (header: time + discount)
--   khata_items            lines now point at their purchase (purchase_id)
--   khata_payments         one row per allocation to a khata; payment_id groups
--                          the allocations of ONE payment made by the customer,
--                          purchase_id marks money handed over with a purchase
--
-- Timestamps are timestamptz (UTC); the app converts to the device timezone.
-- Transaction tables stay insert-only (no update/delete grants).
--
-- Existing data is kept and only annotated:
--   * Legacy item lines of a khata saved within 2 s of each other are treated
--     as one purchase (they were written by a single create_khata call).
--   * A khata's legacy discount is attached to its first purchase.
--   * Legacy payment allocations of one customer within 2 s of each other are
--     treated as one payment.
--   * Money that was paid together with a legacy purchase was never logged;
--     the unlogged remainder of paid_amount is back-filled as one payment
--     stamped right after the khata's first purchase. Its exact original time
--     is unknown, so that is the best available estimate.

begin;

-- 1. Purchases ---------------------------------------------------------------

create table public.khata_purchases (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null default public.current_tenant_id() references public.tenants (id) on delete cascade,
  khata_id    uuid not null references public.khatas (id) on delete cascade,
  discount    numeric(12, 0) not null default 0 check (discount >= 0),
  created_at  timestamptz not null default clock_timestamp()
);

create index khata_purchases_khata_idx  on public.khata_purchases (khata_id, created_at);
create index khata_purchases_tenant_idx on public.khata_purchases (tenant_id, created_at);

alter table public.khata_purchases enable row level security;

create policy khata_purchases_select on public.khata_purchases for select to authenticated
  using (tenant_id = (select public.current_tenant_id()));
create policy khata_purchases_insert on public.khata_purchases for insert to authenticated
  with check (
    tenant_id = (select public.current_tenant_id())
    and exists (
      select 1 from public.khatas k
      where k.id = khata_id and k.tenant_id = (select public.current_tenant_id())
    )
  );

grant select, insert on public.khata_purchases to authenticated;

alter table public.khata_items
  add column purchase_id uuid references public.khata_purchases (id) on delete cascade;
create index khata_items_purchase_idx on public.khata_items (purchase_id);

alter table public.khata_payments
  add column payment_id  uuid not null default gen_random_uuid(),
  add column purchase_id uuid references public.khata_purchases (id) on delete set null;
create index khata_payments_payment_idx on public.khata_payments (payment_id);

-- 2. Back-fill purchases from existing item lines -------------------------------

create temp table _item_groups as
with ordered as (
  select
    li.id, li.khata_id, li.created_at,
    case
      when lag(li.created_at) over w is null
        or li.created_at - lag(li.created_at) over w > interval '2 seconds' then 1
      else 0
    end as is_start
  from public.khata_items li
  window w as (partition by li.khata_id order by li.created_at, li.id)
)
select
  id as item_id, khata_id, created_at,
  sum(is_start) over (partition by khata_id order by created_at, id) as grp
from ordered;

create temp table _purchase_map as
select khata_id, grp, min(created_at) as first_at, gen_random_uuid() as purchase_id
from _item_groups
group by khata_id, grp;

insert into public.khata_purchases (id, tenant_id, khata_id, discount, created_at)
select m.purchase_id, k.tenant_id, m.khata_id, 0, m.first_at
from _purchase_map m
join public.khatas k on k.id = m.khata_id;

update public.khata_items li
set purchase_id = m.purchase_id
from _item_groups g
join _purchase_map m on m.khata_id = g.khata_id and m.grp = g.grp
where li.id = g.item_id;

-- A khata's whole legacy discount goes on its first purchase.
update public.khata_purchases p
set discount = k.discount
from public.khatas k
where k.id = p.khata_id
  and p.id = (
    select p2.id from public.khata_purchases p2
    where p2.khata_id = p.khata_id
    order by p2.created_at, p2.id
    limit 1
  );

alter table public.khata_items alter column purchase_id set not null;

-- 3. Back-fill payment grouping --------------------------------------------------

create temp table _pay_groups as
with ordered as (
  select
    kp.id, k.customer_id, kp.created_at,
    case
      when lag(kp.created_at) over w is null
        or kp.created_at - lag(kp.created_at) over w > interval '2 seconds' then 1
      else 0
    end as is_start
  from public.khata_payments kp
  join public.khatas k on k.id = kp.khata_id
  window w as (partition by k.customer_id order by kp.created_at, kp.id)
)
select
  id, customer_id,
  sum(is_start) over (partition by customer_id order by created_at, id) as grp
from ordered;

create temp table _pay_map as
select customer_id, grp, gen_random_uuid() as payment_id
from _pay_groups
group by customer_id, grp;

update public.khata_payments kp
set payment_id = m.payment_id
from _pay_groups g
join _pay_map m on m.customer_id = g.customer_id and m.grp = g.grp
where kp.id = g.id;

-- Money paid together with a legacy purchase was never logged: add it.
insert into public.khata_payments (tenant_id, khata_id, amount, created_at, purchase_id)
select
  k.tenant_id,
  k.id,
  k.paid_amount - coalesce((select sum(kp.amount) from public.khata_payments kp where kp.khata_id = k.id), 0),
  fp.created_at + interval '1 microsecond',
  fp.id
from public.khatas k
join lateral (
  select p.id, p.created_at from public.khata_purchases p
  where p.khata_id = k.id
  order by p.created_at, p.id
  limit 1
) fp on true
where k.paid_amount - coalesce((select sum(kp.amount) from public.khata_payments kp where kp.khata_id = k.id), 0) > 0;

-- Integrity: nothing was lost or double counted.
do $$
begin
  if (select coalesce(sum(discount), 0) from public.khatas)
     <> (select coalesce(sum(discount), 0) from public.khata_purchases) then
    raise exception 'Ledger back-fill: discount totals differ';
  end if;
  if (select coalesce(sum(paid_amount), 0) from public.khatas)
     <> (select coalesce(sum(amount), 0) from public.khata_payments) then
    raise exception 'Ledger back-fill: paid totals differ';
  end if;
end;
$$;

drop table _item_groups, _purchase_map, _pay_groups, _pay_map;

-- 4. create_khata: one purchase row per call, payment logged separately ------------

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
  v_tenant_id         uuid := (select public.current_tenant_id());
  v_customer_id       uuid;
  v_new_total         numeric;
  v_found             int;
  v_khata_id          uuid;
  v_existing          public.khatas%rowtype;
  v_combined_total    numeric;
  v_combined_discount numeric;
  v_combined_paid     numeric;
  v_purchase_id       uuid;
  v_now               timestamptz := clock_timestamp();
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

  if coalesce(p_discount, 0) < 0 or coalesce(p_paid, 0) < 0 then
    raise exception 'Discount and paid amount can''t be negative';
  end if;

  select id into v_customer_id from public.customers
  where id = p_customer_id and tenant_id = v_tenant_id;
  if v_customer_id is null then
    raise exception 'Customer not found';
  end if;

  select count(*), coalesce(sum(i.price * u.qty), 0) into v_found, v_new_total
  from unnest(p_item_ids, p_quantities) as u(id, qty)
  join public.items i on i.id = u.id;

  if v_found <> array_length(p_item_ids, 1) then
    raise exception 'One or more items were not found';
  end if;

  -- The customer's most recent still-open cycle, locked so two simultaneous
  -- saves can't both read the same totals.
  select * into v_existing
  from public.khatas
  where customer_id = v_customer_id
    and tenant_id = v_tenant_id
    and (total_amount - discount - paid_amount) > 0
  order by created_at desc
  limit 1
  for update;

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
    insert into public.khatas (customer_id, total_amount, discount, paid_amount, created_at)
    values (v_customer_id, v_combined_total, v_combined_discount, v_combined_paid, v_now)
    returning id into v_khata_id;
  end if;

  insert into public.khata_purchases (khata_id, discount, created_at)
  values (v_khata_id, coalesce(p_discount, 0), v_now)
  returning id into v_purchase_id;

  -- Lines share the purchase time, offset by a microsecond to keep their order.
  insert into public.khata_items (khata_id, purchase_id, item_id, item_name, item_price, quantity, item_unit, created_at)
  select v_khata_id, v_purchase_id, i.id, i.name, i.price, u.qty, i.unit,
         v_now + (u.ord * interval '1 microsecond')
  from unnest(p_item_ids, p_quantities) with ordinality as u(id, qty, ord)
  join public.items i on i.id = u.id
  order by u.ord;

  -- Money handed over with the purchase is its own payment record, stamped
  -- after the purchase so the history reads purchase -> payment.
  if coalesce(p_paid, 0) > 0 then
    insert into public.khata_payments (khata_id, amount, purchase_id, created_at)
    values (v_khata_id, p_paid, v_purchase_id,
            v_now + ((array_length(p_item_ids, 1) + 1) * interval '1 microsecond'));
  end if;

  return v_khata_id;
end;
$$;

-- 5. record_customer_payment: one payment_id for all allocations --------------------

create or replace function public.record_customer_payment(
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
  v_payment_id  uuid := gen_random_uuid();
  v_now         timestamptz := clock_timestamp();
begin
  if coalesce(p_amount, 0) <= 0 then
    raise exception 'Enter a payment amount greater than 0';
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
    insert into public.khata_payments (khata_id, amount, payment_id, created_at)
    values (v_khata.id, v_apply, v_payment_id, v_now);

    v_left := v_left - v_apply;
  end loop;
end;
$$;

commit;
