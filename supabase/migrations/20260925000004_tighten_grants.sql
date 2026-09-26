-- Supabase's default privileges hand anon/authenticated broad rights on every
-- new table in public. Row Level Security already blocks most misuse, but the
-- grants should match what the app actually needs, so reset them explicitly.

revoke all on table
  public.tenants, public.tenant_members,
  public.customers, public.items,
  public.khatas, public.khata_items
from anon, authenticated;

-- Signed-in users: read their tenant and edit its contact details only
-- (status and id stay out of reach), read their membership, and read/add
-- catalog and khata rows.
grant select on public.tenants to authenticated;
grant update (name, owner_name, phone, email) on public.tenants to authenticated;
grant select on public.tenant_members to authenticated;
grant select, insert on public.customers   to authenticated;
grant select, insert on public.items       to authenticated;
grant select, insert on public.khatas      to authenticated;
grant select, insert on public.khata_items to authenticated;

revoke execute on function public.set_updated_at() from public, anon, authenticated;
