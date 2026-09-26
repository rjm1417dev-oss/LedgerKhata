-- Khatas (a customer's ledger entry) and the item lines inside each one.

create table public.khatas (
  id             uuid primary key default gen_random_uuid(),
  tenant_id      uuid not null default public.current_tenant_id() references public.tenants (id) on delete cascade,
  customer_id    uuid not null references public.customers (id) on delete restrict,
  customer_name  text not null,
  discount       numeric(12, 0) not null default 0 check (discount >= 0),
  paid           numeric(12, 0) not null default 0 check (paid >= 0),
  created_at     timestamptz not null default now()
);

create table public.khata_items (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null default public.current_tenant_id() references public.tenants (id) on delete cascade,
  khata_id    uuid not null references public.khatas (id) on delete cascade,
  item_id     uuid references public.items (id) on delete set null,
  name        text not null,
  price       numeric(12, 0) not null check (price > 0),
  position    int not null
);

create index khatas_tenant_idx        on public.khatas (tenant_id, created_at desc);
create index khatas_customer_idx      on public.khatas (customer_id);
create index khata_items_khata_idx    on public.khata_items (khata_id);
create index khata_items_tenant_idx   on public.khata_items (tenant_id);
create index khata_items_item_idx     on public.khata_items (item_id);

alter table public.khatas      enable row level security;
alter table public.khata_items enable row level security;

create policy khatas_select on public.khatas for select to authenticated
  using (tenant_id = (select public.current_tenant_id()));
create policy khatas_insert on public.khatas for insert to authenticated
  with check (
    tenant_id = (select public.current_tenant_id())
    and exists (select 1 from public.customers c where c.id = customer_id and c.tenant_id = (select public.current_tenant_id()))
  );

create policy khata_items_select on public.khata_items for select to authenticated
  using (tenant_id = (select public.current_tenant_id()));
create policy khata_items_insert on public.khata_items for insert to authenticated
  with check (
    tenant_id = (select public.current_tenant_id())
    and exists (select 1 from public.khatas k where k.id = khata_id and k.tenant_id = (select public.current_tenant_id()))
  );

grant select, insert on public.khatas      to authenticated;
grant select, insert on public.khata_items to authenticated;

-- Atomic save: the khata and its lines are written in one transaction, and the
-- money rule (discount + paid <= items total) is enforced server-side too.
-- SECURITY INVOKER, so every statement below is subject to the RLS policies.
create function public.create_khata(
  p_customer_id uuid,
  p_item_ids    uuid[],
  p_discount    numeric,
  p_paid        numeric
) returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_customer  public.customers%rowtype;
  v_total     numeric;
  v_found     int;
  v_khata_id  uuid;
begin
  if coalesce(array_length(p_item_ids, 1), 0) = 0 then
    raise exception 'Select at least one item';
  end if;

  select * into v_customer from public.customers where id = p_customer_id;
  if not found then
    raise exception 'Customer not found';
  end if;

  select count(*), coalesce(sum(i.price), 0) into v_found, v_total
  from unnest(p_item_ids) as u(id)
  join public.items i on i.id = u.id;

  if v_found <> array_length(p_item_ids, 1) then
    raise exception 'One or more items were not found';
  end if;

  if coalesce(p_discount, 0) + coalesce(p_paid, 0) > v_total then
    raise exception 'Discount and paid amount can''t be more than the items total';
  end if;

  insert into public.khatas (customer_id, customer_name, discount, paid)
  values (v_customer.id, v_customer.name, coalesce(p_discount, 0), coalesce(p_paid, 0))
  returning id into v_khata_id;

  insert into public.khata_items (khata_id, item_id, name, price, position)
  select v_khata_id, i.id, i.name, i.price, u.ord
  from unnest(p_item_ids) with ordinality as u(id, ord)
  join public.items i on i.id = u.id;

  return v_khata_id;
end;
$$;

revoke all on function public.create_khata(uuid, uuid[], numeric, numeric) from public, anon;
grant execute on function public.create_khata(uuid, uuid[], numeric, numeric) to authenticated;
