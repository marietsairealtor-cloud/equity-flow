-- Canonical wrappers to avoid PostgREST schema-cache + arg-name mismatches.

-- CREATE INVITE (canonical)
drop function if exists public.create_invite_rpc(uuid, text);

create function public.create_invite_rpc(tenant_id uuid, email text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, extensions
as $20260125082652_rpc_wrappers_invite_delete$
declare
  v_token text;
  v_seat_limit int;
  v_seat_count int;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if tenant_id is null or coalesce(email,'') = '' then
    raise exception 'tenant_id and email required';
  end if;

  if to_regclass('public.tenant_invites') is null then
    raise exception 'tenant_invites table missing';
  end if;

  -- must be owner/admin of tenant
  if not public.is_owner_or_admin(tenant_id, auth.uid()) then
    raise exception 'OWNER_OR_ADMIN_ONLY';
  end if;

  -- seat enforcement (block if already full)
  select t.seat_limit, t.seat_count
    into v_seat_limit, v_seat_count
  from public.tenants t
  where t.id = tenant_id;

  if v_seat_limit is not null and v_seat_count is not null and v_seat_count >= v_seat_limit then
    raise exception 'SEAT_LIMIT_REACHED';
  end if;

  -- token
  v_token := encode(extensions.gen_random_bytes(16), 'hex');

  insert into public.tenant_invites(tenant_id, email, token, created_by, revoked_at, accepted_at)
  values (tenant_id, lower(email), v_token, auth.uid(), null, null);

  return jsonb_build_object('ok', true, 'token', v_token, 'tenant_id', tenant_id, 'email', lower(email));
end;
$20260125082652_rpc_wrappers_invite_delete$;

revoke all on function public.create_invite_rpc(uuid, text) from public;
grant execute on function public.create_invite_rpc(uuid, text) to authenticated;

comment on function public.create_invite_rpc(uuid, text) is 'Canonical invite RPC: create_invite_rpc(tenant_id uuid, email text).';

-- DELETE CURRENT WORKSPACE (canonical, no args)
drop function if exists public.delete_current_workspace_rpc();

create function public.delete_current_workspace_rpc()
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $20260125082652_rpc_wrappers_invite_delete$
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
$20260125082652_rpc_wrappers_invite_delete$;

revoke all on function public.delete_current_workspace_rpc() from public;
grant execute on function public.delete_current_workspace_rpc() to authenticated;

comment on function public.delete_current_workspace_rpc() is 'Canonical delete RPC: deletes CURRENT tenant (owner-only).';
