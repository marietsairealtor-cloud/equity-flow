-- Forward-only: app-facing wrappers that match exact JSON param keys.
-- Delegates to *_v1 using dynamic EXECUTE to avoid compile-time dependency.
-- Uses named dollar tags (no $fn$).

begin;

create or replace function public.accept_invite_rpc(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v jsonb;
begin
  if to_regprocedure('public.accept_invite_rpc_v1(text)') is null then
    raise exception 'accept_invite_rpc_v1(text) not found';
  end if;

  execute 'select public.accept_invite_rpc_v1($1)::jsonb' into v using p_token;
  return v;
end;
$fn$;

grant execute on function public.accept_invite_rpc(text) to authenticated;

create or replace function public.revoke_invite_rpc(p_invite_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v jsonb;
begin
  if to_regprocedure('public.revoke_invite_rpc_v1(uuid)') is null then
    raise exception 'revoke_invite_rpc_v1(uuid) not found';
  end if;

  execute 'select public.revoke_invite_rpc_v1($1)::jsonb' into v using p_invite_id;
  return v;
end;
$fn$;

grant execute on function public.revoke_invite_rpc(uuid) to authenticated;

create or replace function public.create_invite_rpc(p_invited_email text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v jsonb;
begin
  if to_regprocedure('public.create_invite_rpc(uuid,text)') is null then
    raise exception 'create_invite_rpc(uuid,text) not found';
  end if;

  execute 'select public.create_invite_rpc($1::uuid, $2::text)::jsonb'
    into v
    using public.current_tenant_id(), p_invited_email;

  return v;
end;
$fn$;

grant execute on function public.create_invite_rpc(text) to authenticated;

-- If already created elsewhere, this is idempotent.
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

grant execute on function public.set_current_tenant_rpc(uuid) to authenticated;

commit;