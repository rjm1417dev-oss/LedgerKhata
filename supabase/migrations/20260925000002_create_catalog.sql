-- Customers and items, scoped to the signed-in user's tenant.
-- tenant_id fills itself from current_tenant_id(), so clients never send it.

create table public.customers (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null default public.current_tenant_id() references public.tenants (id) on delete cascade,
  name        text not null check (length(btrim(name)) > 0),
  phone       text not null check (length(btrim(phone)) > 0),
  created_at  timestamptz not null default now()
);

create table public.items (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null default public.current_tenant_id() references public.tenants (id) on delete cascade,
  name        text not null check (length(btrim(name)) > 0),
  price       numeric(12, 0) not null check (price > 0),
  created_at  timestamptz not null default now()
);

create index customers_tenant_idx on public.customers (tenant_id, created_at);
create index items_tenant_idx     on public.items (tenant_id, created_at);

alter table public.customers enable row level security;
alter table public.items     enable row level security;

create policy customers_select on public.customers for select to authenticated
  using (tenant_id = (select public.current_tenant_id()));
create policy customers_insert on public.customers for insert to authenticated
  with check (tenant_id = (select public.current_tenant_id()));

create policy items_select on public.items for select to authenticated
  using (tenant_id = (select public.current_tenant_id()));
create policy items_insert on public.items for insert to authenticated
  with check (tenant_id = (select public.current_tenant_id()));

-- The app only lists and adds for now; add update/delete grants + policies when
-- edit screens exist.
grant select, insert on public.customers to authenticated;
grant select, insert on public.items     to authenticated;
