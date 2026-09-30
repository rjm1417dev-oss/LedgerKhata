-- Storage for business logos: a public bucket (so Settings can show the
-- logo with a plain Image.network, no signed URLs) with one object per
-- tenant, scoped by the tenant id as the object's top-level folder.

insert into storage.buckets (id, name, public)
values ('business-logos', 'business-logos', true)
on conflict (id) do nothing;

create policy business_logos_select on storage.objects for select to authenticated
  using (bucket_id = 'business-logos');

create policy business_logos_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'business-logos'
    and (storage.foldername(name))[1] = (select public.current_tenant_id())::text
  );

create policy business_logos_update on storage.objects for update to authenticated
  using (
    bucket_id = 'business-logos'
    and (storage.foldername(name))[1] = (select public.current_tenant_id())::text
  )
  with check (
    bucket_id = 'business-logos'
    and (storage.foldername(name))[1] = (select public.current_tenant_id())::text
  );
