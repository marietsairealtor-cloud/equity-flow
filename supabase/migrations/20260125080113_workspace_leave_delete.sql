-- leave workspace (non-owner only)
create or replace function public.leave_workspace(p_tenant_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if not public.is_member(p_tenant_id, auth.uid()) then
    raise exception 'NOT_A_MEMBER';
  end if;

  if exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = p_tenant_id
      and tm.user_id = auth.uid()
      and tm.role::text = 'owner'
  ) then
    raise exception 'OWNER_CANNOT_LEAVE';
  end if;

  delete from public.tenant_memberships
  where tenant_id = p_tenant_id
    and user_id = auth.uid();

  -- if profiles exist, clear current_tenant_id when leaving it
  if to_regclass('public.user_profiles') is not null then
    execute format(
      'update public.user_profiles set current_tenant_id = null where user_id = %L and current_tenant_id = %L',
      auth.uid(), p_tenant_id
    );
  end if;
end;
$$;

revoke all on function public.leave_workspace(uuid) from public;
grant execute on function public.leave_workspace(uuid) to authenticated;

-- delete workspace (owner only)
create or replace function public.delete_workspace(p_tenant_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if not exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = p_tenant_id
      and tm.user_id = auth.uid()
      and tm.role::text = 'owner'
  ) then
    raise exception 'OWNER_ONLY';
  end if;

  -- best-effort cleanup (covers the tables we know exist)
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
end;
$$;

revoke all on function public.delete_workspace(uuid) from public;
grant execute on function public.delete_workspace(uuid) to authenticated;
