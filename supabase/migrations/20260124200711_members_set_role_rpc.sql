create or replace function public.set_member_role(
  p_tenant_id uuid,
  p_user_id uuid,
  p_role text
)
returns void
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $20260124200711_members_set_role_rpc$
declare
  v_owner uuid;
begin
  if p_tenant_id is null or p_user_id is null then
    raise exception 'ARG_REQUIRED';
  end if;

  if public.current_tenant_id() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if not public.is_owner_or_admin(p_tenant_id) then
    raise exception 'NOT_AUTHORIZED';
  end if;

  if p_role not in ('owner','admin','member') then
    raise exception 'INVALID_ROLE';
  end if;

  select tm.user_id into v_owner
  from public.tenant_memberships tm
  where tm.tenant_id = p_tenant_id and tm.role = 'owner'
  limit 1;

  if v_owner is not null and p_user_id = v_owner and p_role <> 'owner' then
    raise exception 'CANNOT_CHANGE_OWNER';
  end if;

  update public.tenant_memberships
  set role = p_role
  where tenant_id = p_tenant_id and user_id = p_user_id;

  if not found then
    raise exception 'NOT_FOUND';
  end if;
end $20260124200711_members_set_role_rpc$;

revoke all on function public.set_member_role(uuid, uuid, text) from public;
grant execute on function public.set_member_role(uuid, uuid, text) to authenticated;
