-- Registration also stores the business address and contact number (both
-- optional). Replaces the 3-argument register_tenant with a 5-argument one.

drop function public.register_tenant(text, text, text);
drop function private.register_tenant(text, text, text);

create function private.register_tenant(
  p_name           text,
  p_owner_name     text,
  p_phone          text,
  p_address        text default null,
  p_contact_number text default null
)
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

  insert into public.tenants (name, address, contact_number)
  values (btrim(p_name), nullif(btrim(coalesce(p_address, '')), ''), nullif(btrim(coalesce(p_contact_number, '')), ''))
  returning id into v_tenant_id;

  insert into public.users (id, tenant_id, name, email, phone)
  values (v_uid, v_tenant_id, btrim(p_owner_name), (select auth.jwt() ->> 'email'), btrim(p_phone));

  return v_tenant_id;
end;
$$;

revoke all on function private.register_tenant(text, text, text, text, text) from public, anon;
grant execute on function private.register_tenant(text, text, text, text, text) to authenticated;

create function public.register_tenant(
  p_name           text,
  p_owner_name     text,
  p_phone          text,
  p_address        text default null,
  p_contact_number text default null
)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select private.register_tenant(p_name, p_owner_name, p_phone, p_address, p_contact_number)
$$;

revoke all on function public.register_tenant(text, text, text, text, text) from public, anon;
grant execute on function public.register_tenant(text, text, text, text, text) to authenticated;
