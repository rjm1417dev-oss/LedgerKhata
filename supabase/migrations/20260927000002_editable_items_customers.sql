-- Items and customers can now be edited and deleted from the app.
--
-- Deleting an item is always safe: khata_items.item_id is ON DELETE SET NULL,
-- so past khata lines keep their saved name/price/unit. Deleting a customer
-- with existing khatas is blocked by khatas.customer_id's ON DELETE RESTRICT
-- (the app checks this up front and shows a friendly message either way).

create policy customers_update on public.customers for update to authenticated
  using (tenant_id = (select public.current_tenant_id()))
  with check (tenant_id = (select public.current_tenant_id()));
create policy customers_delete on public.customers for delete to authenticated
  using (tenant_id = (select public.current_tenant_id()));

create policy items_update on public.items for update to authenticated
  using (tenant_id = (select public.current_tenant_id()))
  with check (tenant_id = (select public.current_tenant_id()));
create policy items_delete on public.items for delete to authenticated
  using (tenant_id = (select public.current_tenant_id()));

grant update, delete on public.customers to authenticated;
grant update, delete on public.items     to authenticated;
