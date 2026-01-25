-- Wrapper RPC to avoid PostgREST schema-cache issues on delete_workspace()
drop function if exists public.delete_workspace_rpc(uuid);

create function public.delete_workspace_rpc(p_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  -- call the underlying function if present; otherwise perform inline delete (same logic)
  if to_regprocedure('public.delete_workspace(uuid)') is not null then
    perform public.delete_workspace(p_tenant_id);
  else
    if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;

    if not exists (
      select 1
      from public.tenant_memberships tm
      where tm.tenant_id = p_tenant_id
        and tm.user_id = auth.uid()
        and tm.role::text = 'owner'
    ) then
      raise exception 'OWNER_ONLY';
    end if;

    if to_regclass('public.documents') is not null then
      execute format('delete from public.documents where tenant_id = %L', p_tenant_id);
    end if;

    if to_regclass('public.deals') is not null then
      execute format('delete from public.deals where tenant_id = %L', p_tenant_id);
    end if;

    if to_regclass('public.tenant_invites') is not null then
      execute format('delete from public.tenant_invites where tenant_id = %L', p_tenant_id);
    end if;

    delete from public.tenant_memberships where tenant_id = p_tenant_id;
    delete from public.tenants where id = p_tenant_id;
  end if;

  return jsonb_build_object('ok', true, 'tenant_id', p_tenant_id);
end;
$$;

revoke all on function public.delete_workspace_rpc(uuid) from public;
grant execute on function public.delete_workspace_rpc(uuid) to authenticated;
comment on function public.delete_workspace_rpc(uuid) is 'Owner-only hard delete of a tenant workspace (RPC wrapper).';

-- Force PostgREST schema cache reload
select pg_notify('pgrst', 'reload schema');
select pg_notify('pgrst', 'reload');