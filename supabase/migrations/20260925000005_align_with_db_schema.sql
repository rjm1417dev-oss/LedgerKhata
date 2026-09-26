-- Reshape the schema to match the project's db_schema file:
--
--   tenants     id, name, created_at, updated_at
--   users       id, tenant_id, name, email, password*, created_at, updated_at
--   customers   id, tenant_id, name, phone, created_at, updated_at
--   items       id, tenant_id, name, price, created_at, updated_at
--   khatas      id, tenant_id, customer_id, total_amount, discount, paid_amount,
--               remaining_amount, created_at, updated_at
--   khata_items id, khata_id, item_id, item_name, item_price, created_at, updated_at
--
-- * `password` is deliberately not a column: Supabase Auth stores the
--   credentials (hashed) in auth.users, and public.users is the profile row for
--   that login (id = auth.users.id). `phone` is added to users because the
--   registration form and Settings screen need the owner's phone number.
--
-- Existing rows are carried over: tenant_members + tenants(owner_name, phone,
-- email) become users rows, khatas gain their stored totals, and khata_items
-- keep their original order through created_at.

-- Users (profile of each auth login, one tenant per user) ---------------------

create table public.users (
  id          uuid primary key references auth.users (id) on delete cascade,
  tenant_id   uuid not null references public.tenants (id) on delete cascade,
  name        text not null check (length(btrim(name)) > 0),
  email       text,
  phone       text not null check (length(btrim(phone)) > 0),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index users_tenant_idx on public.users (tenant_id);

insert into public.users (id, tenant_id, name, email, phone, created_at)
select m.user_id, m.tenant_id, t.owner_name, coalesce(t.email, u.email), t.phone, m.created_at
from public.tenant_members m
join public.tenants t on t.id = m.tenant_id
join auth.users u on u.id = m.user_id;

-- The current tenant now comes from the user's profile row.
create or replace function public.current_tenant_id() returns uuid
language sql
stable
security invoker
set search_path = ''
as $$
  select u.tenant_id from public.users u where u.id = (select auth.uid())
$$;

-- Tenants: id, name, timestamps ------------------------------------------------

drop policy tenants_select on public.tenants;
drop policy tenants_update on public.tenants;
drop table public.tenant_members;

alter table public.tenants
  drop column owner_name,
  drop column phone,
  drop column email,
  drop column status;

create policy tenants_select on public.tenants for select to authenticated
  using (id = (select public.current_tenant_id()));
create policy tenants_update on public.tenants for update to authenticated
  using (id = (select public.current_tenant_id()))
  with check (id = (select public.current_tenant_id()));

alter table public.users enable row level security;

-- A user reads and edits only their own profile. Rows are created by
-- register_tenant(), never directly by a client.
create policy users_select on public.users for select to authenticated
  using (id = (select auth.uid()));
create policy users_update on public.users for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create trigger users_set_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

-- Registration now writes the tenant and the owner's users row.
create or replace function private.register_tenant(p_name text, p_owner_name text, p_phone text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_tenant_id uuid;
begin
  if v_uid is null then
    raise exception 'Please sign in again.';
  end if;
  if exists (select 1 from public.users where id = v_uid) then
    raise exception 'This account already has a business.';
  end if;
  if length(btrim(coalesce(p_name, ''))) = 0 then
    raise exception 'Enter your business name';
  end if;
  if length(btrim(coalesce(p_owner_name, ''))) = 0 then
    raise exception 'Enter the owner name';
  end if;
  if length(btrim(coalesce(p_phone, ''))) = 0 then
    raise exception 'Enter a phone number';
  end if;

  insert into public.tenants (name)
  values (btrim(p_name))
  returning id into v_tenant_id;

  insert into public.users (id, tenant_id, name, email, phone)
  values (v_uid, v_tenant_id, btrim(p_owner_name), (select auth.jwt() ->> 'email'), btrim(p_phone));

  return v_tenant_id;
end;
$$;

-- Customers and items: add updated_at ----------------------------------------

alter table public.customers add column updated_at timestamptz not null default now();
alter table public.items     add column updated_at timestamptz not null default now();

create trigger customers_set_updated_at
  before update on public.customers
  for each row execute function public.set_updated_at();
create trigger items_set_updated_at
  before update on public.items
  for each row execute function public.set_updated_at();

-- Khata items: item_name / item_price, timestamps, no tenant_id or position -----

drop policy khata_items_select on public.khata_items;
drop policy khata_items_insert on public.khata_items;

alter table public.khata_items rename column name  to item_name;
alter table public.khata_items rename column price to item_price;
alter table public.khata_items
  add column created_at timestamptz,
  add column updated_at timestamptz not null default now();

-- Keep the original line order: one microsecond apart, in position order.
update public.khata_items li
set created_at = k.created_at + (li.position * interval '1 microsecond')
from public.khatas k
where k.id = li.khata_id;

alter table public.khata_items
  alter column created_at set not null,
  alter column created_at set default clock_timestamp(),
  drop column position,
  drop column tenant_id;

create trigger khata_items_set_updated_at
  before update on public.khata_items
  for each row execute function public.set_updated_at();

-- Khatas: stored total / paid / remaining --------------------------------------

alter table public.khatas rename column paid to paid_amount;
alter table public.khatas add column total_amount numeric(12, 0);

update public.khatas k
set total_amount = coalesce((select sum(li.item_price) from public.khata_items li where li.khata_id = k.id), 0);

alter table public.khatas
  alter column total_amount set not null,
  add column remaining_amount numeric(12, 0) generated always as (total_amount - discount - paid_amount) stored,
  add column updated_at timestamptz not null default now(),
  add constraint khatas_total_amount_check check (total_amount >= 0),
  add constraint khatas_amounts_check check (discount + paid_amount <= total_amount),
  drop column customer_name;

create trigger khatas_set_updated_at
  before update on public.khatas
  for each row execute function public.set_updated_at();

-- A khata line belongs to a tenant through its khata.
create policy khata_items_select on public.khata_items for select to authenticated
  using (exists (
    select 1 from public.khatas k
    where k.id = khata_id and k.tenant_id = (select public.current_tenant_id())
  ));
create policy khata_items_insert on public.khata_items for insert to authenticated
  with check (exists (
    select 1 from public.khatas k
    where k.id = khata_id and k.tenant_id = (select public.current_tenant_id())
  ));

-- create_khata: same signature, now stores total_amount and the item snapshot.
create or replace function public.create_khata(
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
  v_customer_id uuid;
  v_total       numeric;
  v_found       int;
  v_khata_id    uuid;
begin
  if coalesce(array_length(p_item_ids, 1), 0) = 0 then
    raise exception 'Select at least one item';
  end if;

  select id into v_customer_id from public.customers where id = p_customer_id;
  if v_customer_id is null then
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

  insert into public.khatas (customer_id, total_amount, discount, paid_amount)
  values (v_customer_id, v_total, coalesce(p_discount, 0), coalesce(p_paid, 0))
  returning id into v_khata_id;

  -- created_at ticks per row (clock_timestamp), which keeps the selection order.
  insert into public.khata_items (khata_id, item_id, item_name, item_price)
  select v_khata_id, i.id, i.name, i.price
  from unnest(p_item_ids) with ordinality as u(id, ord)
  join public.items i on i.id = u.id
  order by u.ord;

  return v_khata_id;
end;
$$;

-- Grants: exactly what the app needs ---------------------------------------------

revoke all on table
  public.tenants, public.users,
  public.customers, public.items,
  public.khatas, public.khata_items
from anon, authenticated;

grant select on public.tenants to authenticated;
grant update (name) on public.tenants to authenticated;
grant select on public.users to authenticated;
grant update (name, phone) on public.users to authenticated;
grant select, insert on public.customers   to authenticated;
grant select, insert on public.items       to authenticated;
grant select, insert on public.khatas      to authenticated;
grant select, insert on public.khata_items to authenticated;
