-- (comment cleaned: removed schema-cache wording)
drop function if exists public.delete_current_workspace();

create function public.delete_current_workspace()
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $function$
declare
  v_tenant_id uuid;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_CURRENT_TENANT';
  end if;

  if not exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = v_tenant_id
      and tm.user_id = auth.uid()
      and tm.role::text = 'owner'
  ) then
    raise exception 'OWNER_ONLY';
  end if;

  if to_regclass('public.documents') is not null then
    execute format('delete from public.documents where tenant_id = %L', v_tenant_id);
  end if;

  if to_regclass('public.deals') is not null then
    execute format('delete from public.deals where tenant_id = %L', v_tenant_id);
  end if;

  if to_regclass('public.tenant_invites') is not null then
    execute format('delete from public.tenant_invites where tenant_id = %L', v_tenant_id);
  end if;

  delete from public.tenant_memberships where tenant_id = v_tenant_id;
  delete from public.tenants where id = v_tenant_id;

  return jsonb_build_object('ok', true, 'tenant_id', v_tenant_id);
end;
$function$;

revoke all on function public.delete_current_workspace() from public;
grant execute on function public.delete_current_workspace() to authenticated;

comment on function public.delete_current_workspace() is 'Owner-only hard delete of the CURRENT tenant workspace (no args).';