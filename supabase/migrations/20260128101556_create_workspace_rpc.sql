-- create_workspace RPC (required by app)
create or replace function public.create_workspace(p_workspace_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_tenant_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if p_workspace_name is null or btrim(p_workspace_name) = '' then
    raise exception 'workspace_name_required';
  end if;

  insert into public.tenants (name)
  values (btrim(p_workspace_name))
  returning id into v_tenant_id;

  insert into public.tenant_memberships (tenant_id, user_id, role, tier, status)
  values (v_tenant_id, auth.uid(), 'owner', 'core', 'active');

  update public.user_profiles
     set current_tenant_id = v_tenant_id
   where user_id = auth.uid();

  return v_tenant_id;
end;
$fn$;

grant execute on function public.create_workspace(text) to authenticated;