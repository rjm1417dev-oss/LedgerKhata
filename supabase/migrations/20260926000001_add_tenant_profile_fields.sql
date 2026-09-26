-- Business profile details on the tenant: postal address, logo and a public
-- contact number (shown on the business's khatas/receipts, separate from the
-- owner's personal phone on public.users).
--
-- All three are optional so existing tenants and register_tenant() keep working.
-- logo_url holds a URL (or a Supabase Storage object path) for the logo image.

alter table public.tenants
  add column address        text,
  add column logo_url       text,
  add column contact_number text,
  add constraint tenants_address_check
    check (address is null or length(btrim(address)) > 0),
  add constraint tenants_logo_url_check
    check (logo_url is null or length(btrim(logo_url)) > 0),
  add constraint tenants_contact_number_check
    check (contact_number is null or length(btrim(contact_number)) > 0);

-- Owners can edit these from Settings (name was already editable).
grant update (address, logo_url, contact_number) on public.tenants to authenticated;
