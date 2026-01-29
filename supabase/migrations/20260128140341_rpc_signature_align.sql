-- Align RPC signatures with app payload keys (PostgREST requires param names)
-- Uses named dollar tags (no $fn$). Safe for PowerShell.

begin;

-- If the *internal* versions exist with old param names, rename them to *_v1
do language plpgsql $do$
begin
  -- accept_invite_rpc(token text) -> accept_invite_rpc_v1
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'accept_invite_rpc'
      and pg_get_function_identity_arguments(p.oid) = 'token text'
  ) then
    execute 'alter function public.accept_invite_rpc(text) rename to accept_invite_rpc_v1;';
  end if;

  -- revoke_invite_rpc(invite_id uuid) -> revoke_invite_rpc_v1
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'revoke_invite_rpc'
      and pg_get_function_identity_arguments(p.oid) = 'invite_id uuid'
  ) then
    execute 'alter function public.revoke_invite_rpc(uuid) rename to revoke_invite_rpc_v1;';
  end if;
end
$do$;

-- App-facing wrappers (exact JSON keys the app sends)

create or replace function public.accept_invite_rpc(p_token text)
returns jsonb
language sql
security definer
set search_path = public
as $fn$
  select public.accept_invite_rpc_v1(p_token);
$fn$;

create or replace function public.revoke_invite_rpc(p_invite_id uuid)
returns jsonb
language sql
security definer
set search_path = public
as $fn$
  select public.revoke_invite_rpc_v1(p_invite_id);
$fn$;

-- create_invite_rpc: keep internal (tenant_id uuid, email text) and add wrapper (p_invited_email text)
create or replace function public.create_invite_rpc(p_invited_email text)
returns jsonb
language sql
security definer
set search_path = public
as $fn$
  select public.create_invite_rpc(
    public.current_tenant_id(),
    p_invited_email
  );
$fn$;

create or replace function public.set_current_tenant_rpc(p_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_uid uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if not exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = p_tenant_id
      and tm.user_id = v_uid
  ) then
    raise exception 'not a member of tenant';
  end if;

  if to_regclass('public.profiles') is not null then
    insert into public.profiles (user_id, current_tenant_id)
    values (v_uid, p_tenant_id)
    on conflict (user_id) do update
      set current_tenant_id = excluded.current_tenant_id;
  elsif to_regclass('public.profile') is not null then
    insert into public.profile (user_id, current_tenant_id)
    values (v_uid, p_tenant_id)
    on conflict (user_id) do update
      set current_tenant_id = excluded.current_tenant_id;
  else
    raise exception 'profile table not found (expected public.profiles or public.profile)';
  end if;

  return jsonb_build_object('ok', true, 'tenant_id', p_tenant_id);
end;
$fn$;

grant execute on function public.accept_invite_rpc(text) to authenticated;
grant execute on function public.revoke_invite_rpc(uuid) to authenticated;
grant execute on function public.create_invite_rpc(text) to authenticated;
grant execute on function public.set_current_tenant_rpc(uuid) to authenticated;

commit;