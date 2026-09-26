-- Tenants: every business that registers is one tenant. All app data hangs off
-- a tenant_id, and Row Level Security keeps each tenant's rows invisible to
-- every other tenant.

create table public.tenants (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (length(btrim(name)) > 0),
  owner_name  text not null check (length(btrim(owner_name)) > 0),
  phone       text not null check (length(btrim(phone)) > 0),
  email       text,
  status      text not null default 'active' check (status in ('active', 'suspended')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Which auth users belong to which tenant. unique (user_id) = one tenant per
-- user today; drop that constraint to let one login manage several tenants.
create table public.tenant_members (
  tenant_id   uuid not null references public.tenants (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  role        text not null default 'owner' check (role in ('owner', 'staff')),
  created_at  timestamptz not null default now(),
  primary key (tenant_id, user_id),
  unique (user_id)
);

create function public.set_updated_at() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger tenants_set_updated_at
  before update on public.tenants
  for each row execute function public.set_updated_at();

-- The signed-in user's active tenant. Every tenant-scoped table filters on it.
create function public.current_tenant_id() returns uuid
language sql
stable
security invoker
set search_path = ''
as $$
  select m.tenant_id
  from public.tenant_members m
  join public.tenants t on t.id = m.tenant_id
  where m.user_id = (select auth.uid())
    and t.status = 'active'
  limit 1
$$;

grant execute on function public.current_tenant_id() to authenticated;
revoke execute on function public.current_tenant_id() from public, anon;

alter table public.tenants        enable row level security;
alter table public.tenant_members enable row level security;

create policy tenants_select on public.tenants for select to authenticated
  using (id in (select tenant_id from public.tenant_members where user_id = (select auth.uid())));

create policy tenants_update on public.tenants for update to authenticated
  using (exists (
    select 1 from public.tenant_members m
    where m.tenant_id = tenants.id and m.user_id = (select auth.uid()) and m.role = 'owner'
  ))
  with check (exists (
    select 1 from public.tenant_members m
    where m.tenant_id = tenants.id and m.user_id = (select auth.uid()) and m.role = 'owner'
  ));

create policy tenant_members_select on public.tenant_members for select to authenticated
  using (user_id = (select auth.uid()));

-- Clients can read their tenant and edit its contact details, nothing more.
-- Creating a tenant and joining it happens only through register_tenant().
grant select on public.tenants to authenticated;
grant update (name, owner_name, phone, email) on public.tenants to authenticated;
grant select on public.tenant_members to authenticated;

-- Registration -------------------------------------------------------------
-- Creating the tenant and its first member must be one atomic step that a
-- client is not allowed to do by hand (otherwise anyone could add themselves
-- to any tenant). The SECURITY DEFINER part lives in the unexposed `private`
-- schema, checks auth.uid(), and is reached through a thin public wrapper.

create schema if not exists private;
grant usage on schema private to authenticated;

create function private.register_tenant(p_name text, p_owner_name text, p_phone text)
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
  if exists (select 1 from public.tenant_members where user_id = v_uid) then
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

  insert into public.tenants (name, owner_name, phone, email)
  values (btrim(p_name), btrim(p_owner_name), btrim(p_phone), (select auth.jwt() ->> 'email'))
  returning id into v_tenant_id;

  insert into public.tenant_members (tenant_id, user_id, role)
  values (v_tenant_id, v_uid, 'owner');

  return v_tenant_id;
end;
$$;

revoke all on function private.register_tenant(text, text, text) from public, anon;
grant execute on function private.register_tenant(text, text, text) to authenticated;

create function public.register_tenant(p_name text, p_owner_name text, p_phone text)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select private.register_tenant(p_name, p_owner_name, p_phone)
$$;

revoke all on function public.register_tenant(text, text, text) from public, anon;
grant execute on function public.register_tenant(text, text, text) to authenticated;
